# Scaffold Express Endpoint

Generate a complete Express endpoint following MVC + Service Layer architecture.

This command creates all necessary files for a new endpoint:
- Route definition
- Controller method
- Service method
- Validation schema
- Model (if needed)

---

## Usage

```bash
# Basic usage
claude scaffold-endpoint <resource> <action>

# Examples
claude scaffold-endpoint user create
claude scaffold-endpoint post getAll
claude scaffold-endpoint comment update
claude scaffold-endpoint product delete
```

---

## Parameters

1. **resource** (required): Resource name (singular, e.g., `user`, `post`, `comment`)
2. **action** (required): Action type:
   - `create` - POST endpoint
   - `getAll` - GET collection endpoint
   - `getById` - GET single item endpoint
   - `update` - PUT endpoint
   - `delete` - DELETE endpoint
   - `custom` - Custom endpoint

---

## Scaffolding Templates

### 1. CREATE Endpoint

**Command**: `scaffold-endpoint user create`

#### Generated Files

**`src/routes/users.routes.js`** (create or append):
```javascript
const express = require('express');
const router = express.Router();
const userController = require('../controllers/users.controller');
const { validate } = require('../middlewares/validate.middleware');
const { authenticate } = require('../middlewares/auth.middleware');
const { createUserSchema } = require('../validators/user.validator');

// ... existing routes ...

/**
 * @route   POST /api/v1/users
 * @desc    Create new user
 * @access  Public
 */
router.post('/', validate(createUserSchema), userController.createUser);

module.exports = router;
```

**`src/controllers/users.controller.js`** (create or append):
```javascript
const userService = require('../services/users.service');

/**
 * @desc    Create new user
 * @route   POST /api/v1/users
 * @access  Public
 */
exports.createUser = async (req, res, next) => {
  try {
    const userData = req.body;
    const user = await userService.createUser(userData);

    res.status(201).json({
      success: true,
      data: user,
      message: 'User created successfully'
    });
  } catch (error) {
    next(error);
  }
};
```

**`src/services/users.service.js`** (create or append):
```javascript
const User = require('../models/user.model');
const { ValidationError, ConflictError } = require('../utils/errors');
const bcrypt = require('bcrypt');

/**
 * Create a new user
 * @param {Object} userData - User data
 * @returns {Promise<Object>} Created user
 * @throws {ValidationError} If validation fails
 * @throws {ConflictError} If user already exists
 */
exports.createUser = async (userData) => {
  // Business validation
  if (userData.age && userData.age < 18) {
    throw new ValidationError('User must be at least 18 years old');
  }

  // Check for duplicates
  const existingUser = await User.findOne({ email: userData.email });
  if (existingUser) {
    throw new ConflictError('Email already in use');
  }

  // Hash password if present
  if (userData.password) {
    userData.password = await bcrypt.hash(userData.password, 10);
  }

  // Create user
  const user = await User.create(userData);

  // Remove sensitive data
  const userObject = user.toObject();
  delete userObject.password;

  return userObject;
};
```

**`src/validators/user.validator.js`** (create or append):
```javascript
const { body } = require('express-validator');

/**
 * Validation schema for creating user
 */
exports.createUserSchema = [
  body('name')
    .trim()
    .notEmpty().withMessage('Name is required')
    .isLength({ min: 2, max: 50 }).withMessage('Name must be 2-50 characters'),

  body('email')
    .trim()
    .notEmpty().withMessage('Email is required')
    .isEmail().withMessage('Invalid email format')
    .normalizeEmail(),

  body('password')
    .notEmpty().withMessage('Password is required')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Password must contain uppercase, lowercase, and number'),

  body('age')
    .optional()
    .isInt({ min: 18, max: 120 }).withMessage('Age must be between 18 and 120')
];
```

**`src/models/user.model.js`** (if doesn't exist):
```javascript
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
    minlength: [2, 'Name must be at least 2 characters'],
    maxlength: [50, 'Name must not exceed 50 characters']
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\S+@\S+\.\S+$/, 'Please provide a valid email']
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [8, 'Password must be at least 8 characters'],
    select: false
  },
  age: {
    type: Number,
    min: [18, 'User must be at least 18 years old']
  }
}, {
  timestamps: true
});

// Indexes
userSchema.index({ email: 1 }, { unique: true });

module.exports = mongoose.model('User', userSchema);
```

---

### 2. GET ALL Endpoint

**Command**: `scaffold-endpoint user getAll`

**`src/routes/users.routes.js`**:
```javascript
/**
 * @route   GET /api/v1/users
 * @desc    Get all users
 * @access  Private/Admin
 */
router.get('/', authenticate, authorize('admin'), userController.getAllUsers);
```

**`src/controllers/users.controller.js`**:
```javascript
/**
 * @desc    Get all users
 * @route   GET /api/v1/users
 * @access  Private/Admin
 */
exports.getAllUsers = async (req, res, next) => {
  try {
    const { page = 1, limit = 10, sort = '-createdAt', search } = req.query;
    const result = await userService.getAllUsers({ page, limit, sort, search });

    res.status(200).json({
      success: true,
      data: result.users,
      meta: {
        page: result.page,
        limit: result.limit,
        total: result.total,
        totalPages: result.totalPages
      }
    });
  } catch (error) {
    next(error);
  }
};
```

**`src/services/users.service.js`**:
```javascript
/**
 * Get all users with pagination
 * @param {Object} options - Query options
 * @param {number} options.page - Page number
 * @param {number} options.limit - Items per page
 * @param {string} options.sort - Sort field
 * @param {string} options.search - Search term
 * @returns {Promise<Object>} Users and pagination data
 */
exports.getAllUsers = async ({ page, limit, sort, search }) => {
  page = parseInt(page);
  limit = parseInt(limit);
  const skip = (page - 1) * limit;

  // Build query
  const query = {};
  if (search) {
    query.$or = [
      { name: { $regex: search, $options: 'i' } },
      { email: { $regex: search, $options: 'i' } }
    ];
  }

  // Execute queries in parallel
  const [users, total] = await Promise.all([
    User.find(query)
      .select('-password')
      .sort(sort)
      .skip(skip)
      .limit(limit)
      .lean(),
    User.countDocuments(query)
  ]);

  return {
    users,
    page,
    limit,
    total,
    totalPages: Math.ceil(total / limit)
  };
};
```

---

### 3. GET BY ID Endpoint

**Command**: `scaffold-endpoint user getById`

**`src/routes/users.routes.js`**:
```javascript
/**
 * @route   GET /api/v1/users/:id
 * @desc    Get user by ID
 * @access  Private
 */
router.get('/:id', authenticate, userController.getUserById);
```

**`src/controllers/users.controller.js`**:
```javascript
/**
 * @desc    Get user by ID
 * @route   GET /api/v1/users/:id
 * @access  Private
 */
exports.getUserById = async (req, res, next) => {
  try {
    const userId = req.params.id;
    const user = await userService.getUserById(userId);

    res.status(200).json({
      success: true,
      data: user
    });
  } catch (error) {
    next(error);
  }
};
```

**`src/services/users.service.js`**:
```javascript
const { NotFoundError } = require('../utils/errors');

/**
 * Get user by ID
 * @param {string} userId - User ID
 * @returns {Promise<Object>} User object
 * @throws {NotFoundError} If user not found
 */
exports.getUserById = async (userId) => {
  const user = await User.findById(userId).select('-password').lean();

  if (!user) {
    throw new NotFoundError('User not found');
  }

  return user;
};
```

---

### 4. UPDATE Endpoint

**Command**: `scaffold-endpoint user update`

**`src/routes/users.routes.js`**:
```javascript
/**
 * @route   PUT /api/v1/users/:id
 * @desc    Update user
 * @access  Private
 */
router.put('/:id', authenticate, validate(updateUserSchema), userController.updateUser);
```

**`src/controllers/users.controller.js`**:
```javascript
/**
 * @desc    Update user
 * @route   PUT /api/v1/users/:id
 * @access  Private
 */
exports.updateUser = async (req, res, next) => {
  try {
    const userId = req.params.id;
    const updateData = req.body;
    const user = await userService.updateUser(userId, updateData);

    res.status(200).json({
      success: true,
      data: user,
      message: 'User updated successfully'
    });
  } catch (error) {
    next(error);
  }
};
```

**`src/services/users.service.js`**:
```javascript
/**
 * Update user
 * @param {string} userId - User ID
 * @param {Object} updateData - Data to update
 * @returns {Promise<Object>} Updated user
 * @throws {NotFoundError} If user not found
 */
exports.updateUser = async (userId, updateData) => {
  // Business validation
  if (updateData.age && updateData.age < 18) {
    throw new ValidationError('User must be at least 18 years old');
  }

  // Check if user exists
  const user = await User.findById(userId);
  if (!user) {
    throw new NotFoundError('User not found');
  }

  // Update user
  Object.assign(user, updateData);
  await user.save();

  // Remove sensitive data
  const userObject = user.toObject();
  delete userObject.password;

  return userObject;
};
```

**`src/validators/user.validator.js`**:
```javascript
/**
 * Validation schema for updating user
 */
exports.updateUserSchema = [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 }).withMessage('Name must be 2-50 characters'),

  body('age')
    .optional()
    .isInt({ min: 18, max: 120 }).withMessage('Age must be between 18 and 120')
];
```

---

### 5. DELETE Endpoint

**Command**: `scaffold-endpoint user delete`

**`src/routes/users.routes.js`**:
```javascript
/**
 * @route   DELETE /api/v1/users/:id
 * @desc    Delete user
 * @access  Private/Admin
 */
router.delete('/:id', authenticate, authorize('admin'), userController.deleteUser);
```

**`src/controllers/users.controller.js`**:
```javascript
/**
 * @desc    Delete user
 * @route   DELETE /api/v1/users/:id
 * @access  Private/Admin
 */
exports.deleteUser = async (req, res, next) => {
  try {
    const userId = req.params.id;
    await userService.deleteUser(userId);

    res.status(200).json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};
```

**`src/services/users.service.js`**:
```javascript
/**
 * Delete user
 * @param {string} userId - User ID
 * @returns {Promise<void>}
 * @throws {NotFoundError} If user not found
 */
exports.deleteUser = async (userId) => {
  const user = await User.findById(userId);

  if (!user) {
    throw new NotFoundError('User not found');
  }

  await user.deleteOne();
};
```

---

## Scaffolding Workflow

When you run `scaffold-endpoint <resource> <action>`:

1. **Check existing files**:
   - Does route file exist?
   - Does controller file exist?
   - Does service file exist?
   - Does model file exist?
   - Does validator file exist?

2. **Create missing files**:
   - Create with proper structure and imports
   - Add boilerplate code

3. **Append to existing files**:
   - Add new route to routes file
   - Add new controller method
   - Add new service method
   - Add new validation schema

4. **Update related files**:
   - Register routes in `app.js` if new resource
   - Update API documentation

5. **Verify architecture**:
   - Check file naming
   - Verify layer separation
   - Ensure proper error handling

6. **Output summary**:
```
✅ Endpoint scaffolded successfully!

Files created/updated:
  - src/routes/users.routes.js (appended)
  - src/controllers/users.controller.js (appended)
  - src/services/users.service.js (appended)
  - src/validators/user.validator.js (appended)

Next steps:
  1. Review and customize the generated code
  2. Add any additional business logic
  3. Test the endpoint
  4. Update API documentation

Endpoint: POST /api/v1/users
```

---

## Interactive Mode

For complex scaffolding, use interactive mode:

```bash
claude scaffold-endpoint --interactive
```

**Prompts**:
1. Resource name (singular): `user`
2. Action type: `create`
3. Authentication required? `yes`
4. Authorization roles: `admin, user`
5. Additional fields:
   - Field name: `phoneNumber`
   - Type: `string`
   - Required: `no`
   - Validation: `phone number format`
6. Add another field? `no`

**Generated**: Custom endpoint with specified fields and validation.

---

## Customization Options

Add flags for customization:

```bash
# Skip authentication
scaffold-endpoint user create --no-auth

# Add specific middleware
scaffold-endpoint user create --middleware=rateLimit,cors

# Use different database (Prisma instead of Mongoose)
scaffold-endpoint user create --db=prisma

# Add relationships
scaffold-endpoint post create --relationship="author:User,comments:Comment[]"

# Generate tests
scaffold-endpoint user create --with-tests
```

---

## Generated File Checklist

After scaffolding, verify:

- [ ] Route registered in routes file
- [ ] Controller method created
- [ ] Service method created
- [ ] Validation schema defined
- [ ] Model exists (or created)
- [ ] Proper error handling
- [ ] Standard response format
- [ ] Authentication applied (if needed)
- [ ] Validation middleware applied
- [ ] JSDoc comments added
- [ ] Architecture compliance

---

## Example: Complete User CRUD

```bash
# Generate all CRUD endpoints for User
claude scaffold-endpoint user create
claude scaffold-endpoint user getAll
claude scaffold-endpoint user getById
claude scaffold-endpoint user update
claude scaffold-endpoint user delete

# Or use shorthand
claude scaffold-crud user
```

**Result**: Complete CRUD API for User resource with all files properly structured.

---

**Goal**: Rapidly scaffold new endpoints while maintaining architectural consistency and best practices.
