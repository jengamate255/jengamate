const AdminJS = require('adminjs');
const AdminJSExpress = require('@adminjs/express');
const AdminJSSequelize = require('@adminjs/sequelize');
const express = require('express');
const { Sequelize, DataTypes } = require('sequelize');

AdminJS.registerAdapter(AdminJSSequelize);

// Read DB config from env or default to local Postgres URL
const DATABASE_URL = process.env.DATABASE_URL || 'postgres://postgres:postgres@localhost:5432/jengamate';

const sequelize = new Sequelize(DATABASE_URL, {
  dialect: 'postgres',
  logging: false,
});

// Minimal example model mapping - adjust as needed
const Product = sequelize.define('Product', {
  id: {
    type: DataTypes.UUID,
    primaryKey: true,
  },
  name: DataTypes.STRING,
  price: DataTypes.DOUBLE,
  description: DataTypes.TEXT,
}, { tableName: 'products', timestamps: false });

const run = async () => {
  try {
    await sequelize.authenticate();
    console.log('Connected to DB');

    const adminJs = new AdminJS({
      resources: [
        { resource: Product, options: {} }
      ],
      rootPath: '/admin',
      branding: {
        companyName: 'JengaMate Admin',
      },
    });

    const app = express();

    // Basic auth middleware for AdminJS (simple, replace with real auth in prod)
    const ADMIN_USER = process.env.ADMIN_USER || 'admin';
    const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'password';

    const adminRouter = AdminJSExpress.buildAuthenticatedRouter(
      adminJs,
      {
        authenticate: async (email, password) => {
          if (email === ADMIN_USER && password === ADMIN_PASSWORD) {
            return { email: ADMIN_USER };
          }
          return null;
        },
        cookieName: 'adminjs',
        cookiePassword: process.env.COOKIE_PASSWORD || 'some-secret-password',
      },
      null,
      {
        resave: false,
        saveUninitialized: true,
      }
    );

    app.use(adminJs.options.rootPath, adminRouter);

    const port = process.env.PORT || 3001;
    app.listen(port, () => console.log(`AdminJS running at http://localhost:${port}${adminJs.options.rootPath}`));
  } catch (err) {
    console.error('Failed to start AdminJS', err);
    process.exit(1);
  }
};

run();


