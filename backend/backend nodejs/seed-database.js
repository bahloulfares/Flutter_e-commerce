const fs = require('fs');
const path = require('path');
const sequelize = require('./config/database');
const { Categorie, Scategorie, Article } = require('./models');

async function seedDatabase() {
  try {
    console.log('🌱 Starting database seeding...');
    
    // Connect to database
    await sequelize.authenticate();
    console.log('✅ Database connected');

    // Read JSON files
    const categoriesData = JSON.parse(
      fs.readFileSync(path.join(__dirname, '../DataBaseCommerce2024/categories.json'), 'utf-8')
    );
    const scategoriesData = JSON.parse(
      fs.readFileSync(path.join(__dirname, '../DataBaseCommerce2024/scategories.json'), 'utf-8')
    );
    const articlesData = JSON.parse(
      fs.readFileSync(path.join(__dirname, '../DataBaseCommerce2024/articles.json'), 'utf-8')
    );

    console.log(`📦 Found ${categoriesData.length} categories, ${scategoriesData.length} subcategories, ${articlesData.length} articles`);

    // Clear existing data (optional - comment out if you want to keep existing data)
    await Article.destroy({ where: {}, truncate: false });
    await Scategorie.destroy({ where: {}, truncate: false });
    await Categorie.destroy({ where: {}, truncate: false });
    console.log('🗑️  Cleared existing data');

    // Seed Categories
    const categoryMap = new Map(); // Map old MongoDB IDs to new MySQL IDs
    for (const cat of categoriesData) {
      const mongoId = cat._id.$oid;
      const newCat = await Categorie.create({
        nomcategorie: cat.nomcategorie,
        imagecategorie: cat.imagecategorie
      });
      categoryMap.set(mongoId, newCat.id);
    }
    console.log(`✅ Seeded ${categoryMap.size} categories`);

    // Seed Subcategories
    const scategoryMap = new Map(); // Map old MongoDB IDs to new MySQL IDs
    for (const scat of scategoriesData) {
      const mongoId = scat._id.$oid;
      const mongoCategoryId = scat.categorieID.$oid;
      const newCategoryId = categoryMap.get(mongoCategoryId);
      
      if (newCategoryId) {
        const newScat = await Scategorie.create({
          nomscategorie: scat.nomscategorie,
          imagescat: scat.imagescategorie, // Map imagescategorie to imagescat
          categorieId: newCategoryId // Use categorieId (not categorieID)
        });
        scategoryMap.set(mongoId, newScat.id);
      }
    }
    console.log(`✅ Seeded ${scategoryMap.size} subcategories`);

    // Seed Articles
    let articlesCount = 0;
    for (const art of articlesData) {
      const mongoScategoryId = art.scategorieID?.$oid;
      const newScategoryId = scategoryMap.get(mongoScategoryId);
      
      if (newScategoryId) {
        await Article.create({
          designation: art.designation,
          marque: art.marque,
          reference: art.reference,
          prix: art.prix,
          imageart: art.imageart,
          qtestock: art.qtestock,
          scategorieId: newScategoryId // Use scategorieId (not scategorieID)
        });
        articlesCount++;
      }
    }
    console.log(`✅ Seeded ${articlesCount} articles`);

    // Verify data
    const catCount = await Categorie.count();
    const scatCount = await Scategorie.count();
    const artCount = await Article.count();
    
    console.log('\n📊 Database Summary:');
    console.log(`   Categories: ${catCount}`);
    console.log(`   Subcategories: ${scatCount}`);
    console.log(`   Articles: ${artCount}`);
    console.log('\n🎉 Database seeding completed successfully!');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Seeding failed:', error);
    process.exit(1);
  }
}

seedDatabase();
