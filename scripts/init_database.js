const admin = require('firebase-admin');
const serviceAccount = require('../key.properties.example');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://your-project-id.firebaseio.com'
});

const db = admin.firestore();

// Dummy data structures
const commissionTiers = {
  engineer: [
    {
      role: 'engineer',
      name: 'bronze',
      badgeText: 'Bronze Engineer',
      badgeColor: 'bronze',
      minProducts: 5,
      minTotalValue: 1000.0,
      ratePercent: 0.02,
      order: 1,
    },
    {
      role: 'engineer',
      name: 'silver',
      badgeText: 'Silver Engineer',
      badgeColor: 'silver',
      minProducts: 15,
      minTotalValue: 5000.0,
      ratePercent: 0.04,
      order: 2,
    },
    {
      role: 'engineer',
      name: 'gold',
      badgeText: 'Gold Engineer',
      badgeColor: 'gold',
      minProducts: 30,
      minTotalValue: 15000.0,
      ratePercent: 0.06,
      order: 3,
    },
    {
      role: 'engineer',
      name: 'platinum',
      badgeText: 'Platinum Engineer',
      badgeColor: 'platinum',
      minProducts: 50,
      minTotalValue: 30000.0,
      ratePercent: 0.08,
      order: 4,
    },
  ],
  supplier: [
    {
      role: 'supplier',
      name: 'bronze',
      badgeText: 'Bronze Supplier',
      badgeColor: 'bronze',
      minProducts: 10,
      minTotalValue: 2000.0,
      ratePercent: 0.015,
      order: 1,
    },
    {
      role: 'supplier',
      name: 'silver',
      badgeText: 'Silver Supplier',
      badgeColor: 'silver',
      minProducts: 25,
      minTotalValue: 10000.0,
      ratePercent: 0.03,
      order: 2,
    },
    {
      role: 'supplier',
      name: 'gold',
      badgeText: 'Gold Supplier',
      badgeColor: 'gold',
      minProducts: 50,
      minTotalValue: 30000.0,
      ratePercent: 0.045,
      order: 3,
    },
    {
      role: 'supplier',
      name: 'platinum',
      badgeText: 'Platinum Supplier',
      badgeColor: 'platinum',
      minProducts: 100,
      minTotalValue: 75000.0,
      ratePercent: 0.06,
      order: 4,
    },
  ]
};

const categories = [
  { name: 'Electronics', description: 'Electronic devices and components' },
  { name: 'Construction', description: 'Construction materials and tools' },
  { name: 'Automotive', description: 'Automotive parts and accessories' },
  { name: 'Industrial', description: 'Industrial equipment and supplies' },
  { name: 'Agriculture', description: 'Agricultural tools and equipment' },
  { name: 'Healthcare', description: 'Medical and healthcare equipment' },
  { name: 'Textiles', description: 'Textile materials and products' },
  { name: 'Food & Beverage', description: 'Food processing and beverage equipment' },
];

const systemConfig = {
  order_statuses: ['PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED', 'REFUNDED'],
  inquiry_statuses: ['PENDING', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'],
  priorities: ['LOW', 'MEDIUM', 'HIGH', 'URGENT'],
  content_types: ['product', 'review', 'message', 'profile', 'inquiry'],
  severity_levels: ['low', 'medium', 'high', 'critical'],
  rfq_statuses: ['Pending', 'Approved', 'Rejected', 'Processing', 'Completed'],
  rfq_types: ['Standard', 'Bid', 'Catalog', 'Marketplace'],
  last_sync: admin.firestore.FieldValue.serverTimestamp(),
};

const rolePermissions = {
  super_admin: {
    permissions: {
      'users:read': true,
      'users:write': true,
      'users:delete': true,
      'roles:manage': true,
      'system:admin': true,
      'audit:read': true,
      'gdpr:manage': true,
    },
    description: 'Full system access',
  },
  admin: {
    permissions: {
      'users:read': true,
      'users:write': true,
      'users:delete': false,
      'roles:assign': true,
      'audit:read': true,
      'gdpr:read': true,
    },
    description: 'Administrative access',
  },
  moderator: {
    permissions: {
      'users:read': true,
      'users:write': true,
      'users:delete': false,
      'content:moderate': true,
    },
    description: 'Content moderation access',
  },
  user: {
    permissions: {
      'profile:read': true,
      'profile:write': true,
      'content:read': true,
      'content:write': true,
    },
    description: 'Standard user access',
  },
  guest: {
    permissions: {
      'content:read': true,
    },
    description: 'Read-only access',
  },
};

async function initializeDatabase() {
  try {
    console.log('Starting database initialization...');

    // Initialize commission tiers
    console.log('Initializing commission tiers...');
    for (const [role, tiers] of Object.entries(commissionTiers)) {
      for (const tier of tiers) {
        const docId = `${tier.role}_${tier.name}`;
        await db.collection('commission_tiers').doc(docId).set(tier);
        console.log(`Created commission tier: ${docId}`);
      }
    }

    // Initialize categories
    console.log('Initializing categories...');
    for (const category of categories) {
      const docId = category.name.toLowerCase().replace(/\s+/g, '_');
      await db.collection('categories').doc(docId).set({
        ...category,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
      });
      console.log(`Created category: ${category.name}`);
    }

    // Initialize system configuration
    console.log('Initializing system configuration...');
    await db.collection('system_config').doc('app_config').set(systemConfig);
    console.log('Created system configuration');

    // Initialize role permissions
    console.log('Initializing role permissions...');
    for (const [role, permissions] of Object.entries(rolePermissions)) {
      await db.collection('role_permissions').doc(role).set(permissions);
      console.log(`Created role permissions: ${role}`);
    }

    console.log('Database initialization completed successfully!');
  } catch (error) {
    console.error('Error initializing database:', error);
    process.exit(1);
  }
}

// Run the initialization
initializeDatabase().then(() => {
  console.log('Database initialization script completed.');
  process.exit(0);
}).catch((error) => {
  console.error('Script failed:', error);
  process.exit(1);
});