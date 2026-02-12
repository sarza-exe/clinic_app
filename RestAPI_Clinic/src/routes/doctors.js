// src/routes/doctors.js
const express = require('express');
const router = express.Router();
const doctorCtrl = require('../controllers/doctors');
const authJWT = require('../middleware/authJWT');

// Public routes
router.get('/', doctorCtrl.getAll);
router.get('/:id', doctorCtrl.getById);
router.get('/specialty/:specialty', doctorCtrl.getBySpecialty);

// Protected routes (require valid JWT)
router.put('/:id', authJWT, doctorCtrl.update);
router.delete('/:id', authJWT, doctorCtrl.remove);
router.patch('/:id/password', authJWT, doctorCtrl.changePassword)

module.exports = router;
