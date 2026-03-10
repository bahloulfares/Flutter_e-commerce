const bcrypt = require('bcrypt');
const { User } = require('./models');
const sequelize = require('./config/database');

async function createAdmin() {
  try {
    console.log('🔍 Recherche d\'un utilisateur admin existant...');
    
    // Vérifier si l'admin existe déjà
    const existingAdmin = await User.findOne({ 
      where: { email: 'admin@test.com' } 
    });

    if (existingAdmin) {
      console.log('⚠️  Un utilisateur avec cet email existe déjà');
      console.log(`   Nom: ${existingAdmin.name}`);
      console.log(`   Email: ${existingAdmin.email}`);
      console.log(`   Rôle actuel: ${existingAdmin.role}`);
      
      if (existingAdmin.role === 'admin') {
        console.log('✅ Cet utilisateur est déjà admin. Rien à faire.');
      } else {
        console.log('🔄 Mise à jour du rôle vers "admin"...');
        await existingAdmin.update({ role: 'admin' });
        console.log('✅ Rôle mis à jour avec succès vers "admin"');
      }
      
      console.log('\n📋 Informations de connexion :');
      console.log('   Email: admin@test.com');
      console.log('   Mot de passe: admin123 (si inchangé)');
      console.log('   Rôle: admin');
      
      return;
    }

    // Créer un nouvel admin
    console.log('🔨 Création d\'un nouvel utilisateur admin...');
    const hashedPassword = await bcrypt.hash('admin123', 10);
    
    const admin = await User.create({
      name: 'Admin Test',
      email: 'admin@test.com',
      password: hashedPassword,
      role: 'admin'
    });

    console.log('✅ Compte admin créé avec succès !');
    console.log('\n📋 Informations de connexion :');
    console.log(`   ID: ${admin.id}`);
    console.log(`   Nom: ${admin.name}`);
    console.log(`   Email: ${admin.email}`);
    console.log(`   Mot de passe: admin123`);
    console.log(`   Rôle: ${admin.role}`);
    
    console.log('\n🎯 Prochaines étapes :');
    console.log('   1. Lancez l\'application Flutter');
    console.log('   2. Connectez-vous avec admin@test.com / admin123');
    console.log('   3. Vérifiez que le drawer est ROSE avec le badge ADMIN');
    console.log('   4. Le menu "Catégories" devrait être visible');
    
  } catch (error) {
    console.error('❌ Erreur lors de la création de l\'admin :');
    console.error(error);
  } finally {
    console.log('\n👋 Terminé.');
    process.exit();
  }
}

// Connexion à la base de données et exécution
sequelize.authenticate()
  .then(() => {
    console.log('✅ Connexion à la base de données réussie\n');
    return createAdmin();
  })
  .catch(err => {
    console.error('❌ Impossible de se connecter à la base de données:', err);
    process.exit(1);
  });
