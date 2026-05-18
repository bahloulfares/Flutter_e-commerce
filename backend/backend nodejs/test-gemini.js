require('dotenv').config();
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { Article } = require('./models');

async function testChatbot() {
  console.log('=== TEST CHATBOT GEMINI + MySQL ===\n');
  
  // 1. Test MySQL
  try {
    const articles = await Article.findAll({ limit: 3 });
    console.log('✅ MySQL OK —', articles.length, 'produits trouvés:');
    articles.forEach(a => console.log('   -', a.designation, '|', a.prix, 'DA | stock:', a.qtestock));
  } catch(e) {
    console.log('❌ MySQL:', e.message);
  }

  // 2. Test Gemini
  const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  const model = genAI.getGenerativeModel({ model: 'gemini-flash-lite-latest' });
  
  const prompt = [
    'Tu es assistant e-commerce. Reponds en JSON strict UNIQUEMENT, sans backticks.',
    'Produits disponibles: Samsung A54 - 45000 DA - Stock: 10',
    'Format: {"intent": "productSearch", "message": "ta reponse", "searchTerm": "samsung"}',
    'Question utilisateur: je cherche un samsung pas cher'
  ].join('\n');

  try {
    const r = await model.generateContent(prompt);
    const text = r.response.text().trim()
      .replace(/```json/gi, '').replace(/```/gi, '').trim();
    console.log('\n✅ Gemini répond (brut):', text);
    const json = JSON.parse(text);
    console.log('✅ JSON parsé OK — Intent:', json.intent, '| Message:', json.message.substring(0, 60));
  } catch(e) {
    console.log('❌ Gemini:', e.message.substring(0, 200));
  }

  process.exit(0);
}

testChatbot();
