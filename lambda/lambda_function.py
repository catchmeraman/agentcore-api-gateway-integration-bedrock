import json
import boto3
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')
table = dynamodb.Table('PetStore')

def lambda_handler(event, context):
    print(f"Event: {json.dumps(event)}")
    
    path = event.get('path', '')
    method = event.get('httpMethod', '')
    
    # Handle OPTIONS preflight
    if method == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                'Access-Control-Max-Age': '86400'
            },
            'body': ''
        }
    
    # Natural language query endpoint
    if path == '/pets/query' and method == 'POST':
        body_str = event.get('body', '{}')
        body = json.loads(body_str) if body_str else {}
        user_query = body.get('query', '')
        
        # Get all pets
        response = table.scan()
        pets = response.get('Items', [])
        
        # Use Bedrock to understand query and filter
        result = query_with_llm(user_query, pets)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(result, default=str)
        }
    
    # Standard GET /pets
    if path == '/pets' and method == 'GET':
        response = table.scan()
        pets = response.get('Items', [])
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(pets, default=str)
        }
    
    # Standard POST /pets
    if path == '/pets' and method == 'POST':
        body_str = event.get('body', '{}')
        body = json.loads(body_str) if body_str else {}
        
        response = table.scan(ProjectionExpression='id')
        ids = [item['id'] for item in response.get('Items', [])]
        next_id = max(ids) + 1 if ids else 1
        
        pet = {
            'id': next_id,
            'name': body.get('name', 'Unknown'),
            'type': body.get('type', 'unknown'),
            'breed': body.get('breed', 'Mixed'),
            'age': int(body.get('age', 1)),
            'price': int(body.get('price', 100))
        }
        
        table.put_item(Item=pet)
        
        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps(pet, default=str)
        }
    
    return {
        'statusCode': 404,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'error': 'Not found'})
    }

def query_with_llm(user_query, pets):
    """Use Bedrock LLM to understand query and filter pets"""
    
    # Create tool definition for LLM
    tools = [{
        "toolSpec": {
            "name": "filter_pets",
            "description": "Filter and sort pets based on user criteria",
            "inputSchema": {
                "json": {
                    "type": "object",
                    "properties": {
                        "type_filter": {
                            "type": "string",
                            "description": "Pet type to filter (dog, cat, bird, etc). Empty for all types."
                        },
                        "sort_by": {
                            "type": "string",
                            "enum": ["price_asc", "price_desc", "age_asc", "age_desc", "name"],
                            "description": "How to sort results"
                        },
                        "max_price": {
                            "type": "integer",
                            "description": "Maximum price filter"
                        },
                        "min_price": {
                            "type": "integer",
                            "description": "Minimum price filter"
                        }
                    }
                }
            }
        }
    }]
    
    # Call Bedrock Converse API
    try:
        converse_response = bedrock.converse(
            modelId="us.amazon.nova-micro-v1:0",  # Cheapest model
            messages=[{
                "role": "user",
                "content": [{"text": f"User query: {user_query}\n\nAnalyze this query and call the filter_pets tool with appropriate parameters."}]
            }],
            toolConfig={"tools": tools}
        )
        
        # Extract tool use
        output = converse_response['output']['message']['content']
        
        for content in output:
            if 'toolUse' in content:
                tool_input = content['toolUse']['input']
                
                # Apply filters
                filtered_pets = pets
                
                # Type filter
                if tool_input.get('type_filter'):
                    filtered_pets = [p for p in filtered_pets if p['type'].lower() == tool_input['type_filter'].lower()]
                
                # Price filters
                if tool_input.get('max_price'):
                    filtered_pets = [p for p in filtered_pets if p['price'] <= tool_input['max_price']]
                if tool_input.get('min_price'):
                    filtered_pets = [p for p in filtered_pets if p['price'] >= tool_input['min_price']]
                
                # Sort
                sort_by = tool_input.get('sort_by', 'name')
                if sort_by == 'price_asc':
                    filtered_pets.sort(key=lambda x: x['price'])
                elif sort_by == 'price_desc':
                    filtered_pets.sort(key=lambda x: x['price'], reverse=True)
                elif sort_by == 'age_asc':
                    filtered_pets.sort(key=lambda x: x['age'])
                elif sort_by == 'age_desc':
                    filtered_pets.sort(key=lambda x: x['age'], reverse=True)
                else:
                    filtered_pets.sort(key=lambda x: x['name'])
                
                return {
                    'pets': filtered_pets[:10],  # Limit to 10 results
                    'count': len(filtered_pets),
                    'filters_applied': tool_input
                }
        
        # Fallback if no tool use
        return {'pets': pets[:10], 'count': len(pets), 'filters_applied': {}}
        
    except Exception as e:
        print(f"LLM Error: {e}")
        # Fallback to simple keyword matching
        return simple_filter(user_query, pets)

def simple_filter(query, pets):
    """Fallback simple filtering"""
    query_lower = query.lower()
    filtered = pets
    
    # Type filter
    for pet_type in ['dog', 'cat', 'bird', 'fish']:
        if pet_type in query_lower:
            filtered = [p for p in filtered if p['type'].lower() == pet_type]
            break
    
    # Sort
    if any(word in query_lower for word in ['expensive', 'costlier', 'costly']):
        filtered.sort(key=lambda x: x['price'], reverse=True)
    elif any(word in query_lower for word in ['cheap', 'affordable']):
        filtered.sort(key=lambda x: x['price'])
    
    return {'pets': filtered[:10], 'count': len(filtered), 'filters_applied': {'fallback': True}}
