const express = require('express');
const router  = express.Router();
const patientCtrl = require('../controllers/patients');


router.get('/', patientCtrl.getAll); // GET /patients
router.get('/:id', patientCtrl.getById); // GET /patients/:id
router.get('/doctor/:doctorId', patientCtrl.getByDoctor); // GET /patients/doctors/:id
router.get('/:id/appointments', patientCtrl.getAppointmentsByPatient);
router.put('/:id', patientCtrl.update); // PUT /patients/:id
router.delete('/:id', patientCtrl.remove); // DELETE /patients/:id
router.patch('/:id/password', patientCtrl.changePassword)

module.exports = router;
