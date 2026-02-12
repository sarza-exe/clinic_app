const express = require('express');
const router  = express.Router();
const appointmentCtrl = require('../controllers/appointments');



// GET /appointments
router.get('/', appointmentCtrl.getAppointments); // getAll

// GET /appointments/:id
router.get('/:id', appointmentCtrl.getById);

// POST /appointments
router.post('/', appointmentCtrl.create);

// PUT /appointments/:id
router.put('/:id', appointmentCtrl.update);

// DELETE /appointments/:id
router.delete('/:id', appointmentCtrl.remove);

module.exports = router;
