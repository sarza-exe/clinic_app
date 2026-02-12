const bcrypt = require('bcryptjs');
const Patient = require('../models/patient');
const Appointment = require('../models/appointment');

// GET /patients?page=&limit=
exports.getAll = async (req, res, next) => {
    try{
	const { id: requesterId, role: requesterRole } = req.user;
        // only admin or doctor
        if (requesterRole !== 'admin' && requesterRole !== 'doctor') {
            return res.status(403).json({ error: 'Forbidden' });
        }
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 20;
        const skip = (page - 1) * limit;

        const [total, patients] = await Promise.all([
            Patient.countDocuments(),
            Patient.find()
                .select('-passwordHash')
                .skip(skip)
                .limit(limit)
                .sort({createdAt: -1})
        ]);

        res.json({ page, limit, total, data: patients });
    } catch (err) {
        next(err);
    }
};


// GET /patients/:id
exports.getById = async (req, res, next) => {
  try {
    const patient = await Patient.findById(req.params.id).select('-passwordHash');
    if (!patient) return res.status(404).json({ error: 'Patient not found' });
    res.json(patient);
  } catch (err) {
    next(err);
  }
};

// GET /patients/doctor/:doctorId
// it is here instead of a filter to underline it's different
// this one needs doctor role
exports.getByDoctor = async (req, res, next) => {
  try {
    const { id: requesterId, role: requesterRole } = req.user;
    if (requesterRole !== 'admin' && requesterRole !== 'doctor') {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const { doctorId } = req.params;
    // get patients who have/had appointments associated with the doctor
    const appts = await Appointment.find({ doctor: doctorId })
      .populate('patient', '-passwordHash');
    const patientsMap = {};
    appts.forEach(a => {
      const p = a.patient.toObject();
      delete p.passwordHash;
      patientsMap[p._id] = p;
    });
    const patients = Object.values(patientsMap);
    res.json(patients);
  } catch (err) {
    next(err);
  }
};

// GET /patients/:id/appointments
exports.getAppointmentsByPatient = async (req, res, next) => {
  try {
    const { id: requesterId, role: requesterRole } = req.user;
    const patientId = req.params.id;
    // only admin or the patient themselves
    if (requesterRole !== 'admin' && requesterRole !== 'doctor' && requesterId !== patientId) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const appointments = await Appointment.find({ patient: patientId })
      .populate('doctor', 'name specialty email')
      .sort({ date: 1 });
    res.json(appointments);
  } catch (err) {
    next(err);
  }
};

// PUT /patients/:id
exports.update = async (req, res, next) => {
  try {
    const { id: requesterId, role: requesterRole } = req.user;
    if (requesterRole !== 'admin' && requesterId !== req.params.id) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const updates = { ...req.body };
    if (updates.password) {
      updates.passwordHash = await bcrypt.hash(updates.password, 10);
      delete updates.password;
    }
    const patient = await Patient.findByIdAndUpdate(
      req.params.id,
      updates,
      { new: true, runValidators: true }
    ).select('-passwordHash');
    if (!patient) return res.status(404).json({ error: 'Patient not found' });
    res.json(patient);
  } catch (err) {
    next(err);
  }
};

// PATCH /patients/:id/password
exports.changePassword = async (req, res, next) => {
  try {
    const { id: requesterId, role } = req.user;
    const targetId = req.params.id;

    // only admin or the patient themselves
    if (role !== 'admin' && requesterId !== targetId) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    const { password } = req.body;
    if (!password) {
      return res.status(400).json({ error: 'New password is required' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    
    const patient = await Patient.findByIdAndUpdate(targetId, { passwordHash });
    if (!patient) return res.status(404).json({ error: 'Patient not found' });

    res.json({ message: 'Password updated' });
  } catch (err) {
    next(err);
  }
};

// DELETE /patients/:id
exports.remove = async (req, res, next) => {
  try {
    const { id: requesterId, role: requesterRole } = req.user;
    if (requesterRole !== 'admin' && requesterId !== req.params.id) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const patient = await Patient.findByIdAndDelete(req.params.id);
    if (!patient) return res.status(404).json({ error: 'Patient not found' });
    res.status(204).end();
  } catch (err) {
    next(err);
  }
};
