# Pet Store Chatbot - Demo Questions Guide

## ✅ QUESTIONS YOU CAN ASK

### List & Browse Pets
- "List all pets"
- "Show me all available pets"
- "What pets do you have?"
- "Display the pet inventory"

### Filter by Type
- "Show me dogs"
- "What cats do you have?"
- "List all birds"
- "Show me fish"
- "Do you have any hamsters?"
- "Show me rabbits"

### Search by Name
- "Tell me about Buddy"
- "Show me Max"
- "What do you know about Whiskers?"
- "Find Charlie"

### Price Queries
- "What are the cheapest pets?"
- "Show me affordable pets"
- "Which pets are under $200?"
- "What's the most expensive pet?"

### Add New Pets
- "Add a dog named Max, breed: Labrador, age: 3, price: $600"
- "Add a cat named Luna, breed: Persian, age: 2, price: $400"
- "Add a bird named Tweety, breed: Canary, age: 1, price: $150"
- "Add a fish named Nemo, breed: Clownfish, age: 1, price: $50"

### Combinations
- "Show me dogs under $500"
- "List all young pets" (age-based)
- "What's the cheapest dog?"

---

## ❌ QUESTIONS YOU CAN'T ASK (Not Implemented)

### Update Operations
- "Update Buddy's price to $300" ❌
- "Change Max's age to 4" ❌
- "Rename Whiskers to Fluffy" ❌

### Delete Operations
- "Delete the pet named Max" ❌
- "Remove all birds" ❌
- "Delete pet ID 5" ❌

### Complex Queries
- "Show me pets added in the last week" ❌
- "Which pets are most popular?" ❌
- "Show me pets by owner" ❌
- "What's the average price of dogs?" ❌

### Inventory Management
- "Mark Buddy as sold" ❌
- "Reserve Max for me" ❌
- "Check availability of Luna" ❌

### Advanced Filters
- "Show me pets between 2-5 years old" ❌
- "List pets by price range $200-$500" ❌
- "Show me pets sorted by age" ❌

### Pet Details Beyond Basic Info
- "What's Buddy's vaccination status?" ❌
- "Show me photos of Max" ❌
- "What's the health history of Whiskers?" ❌
- "Does Luna get along with other pets?" ❌

### Business Operations
- "How many pets were sold this month?" ❌
- "What's the total inventory value?" ❌
- "Show me sales reports" ❌

---

## 🎯 DEMO SCRIPT (Recommended Order)

1. **Start Simple**
   - "List all pets"
   - "Show me dogs"

2. **Show Search**
   - "Tell me about Buddy"

3. **Show Filtering**
   - "What are the cheapest pets?"

4. **Demonstrate Add (Main Feature)**
   - "Add a dog named Rocky, breed: Bulldog, age: 2, price: $700"

5. **Verify Addition**
   - "List all pets" (Rocky should appear!)
   - "Show me dogs" (Rocky in the list)

6. **Add Another**
   - "Add a cat named Mittens, breed: Tabby, age: 1, price: $200"

7. **Final Verification**
   - "List all pets" (both new pets visible)

---

## 💡 TIPS FOR DEMO

### What Works Best
- Use natural language (no need for exact syntax)
- Pet names should start with capital letter
- Include all fields when adding: name, type, breed, age, price
- Types supported: dog, cat, bird, fish, hamster, rabbit, turtle, guinea pig, lizard, frog

### Common Patterns
```
Add a [TYPE] named [NAME], breed: [BREED], age: [AGE], price: $[PRICE]
```

### Examples That Work
✅ "Add a dog named Max, breed: Labrador, age: 3, price: $600"
✅ "Add a cat named Luna, breed: Persian, age: 2, price: $400"
✅ "Show me all dogs"
✅ "What are the cheapest pets?"

### Examples That Don't Work
❌ "Add Max" (missing required fields)
❌ "Update Buddy's price" (update not implemented)
❌ "Delete all cats" (delete not implemented)
❌ "Show me pets added today" (no timestamp tracking)

---

## 🔧 TECHNICAL LIMITATIONS

### Current Implementation
- **GET Operations**: Via AgentCore Gateway (MCP protocol)
- **POST Operations**: Direct API Gateway call
- **Storage**: DynamoDB (persistent)
- **No Authentication**: Public demo

### Why Some Features Don't Work
1. **No UPDATE/DELETE**: Lambda only implements GET and POST
2. **No Advanced Queries**: Simple DynamoDB scan (no complex filters)
3. **No Sorting**: Results returned in DynamoDB order
4. **No Pagination**: All results returned at once
5. **No Validation**: Basic field validation only

---

## 📊 CURRENT DATABASE

Your store currently has these pets (as of last check):
- 18+ pets total
- Mix of dogs, cats, birds, fish, and other animals
- Prices range from ~$1 to ~$800
- Ages range from 1 to 10 years

Use "List all pets" to see the current inventory!
