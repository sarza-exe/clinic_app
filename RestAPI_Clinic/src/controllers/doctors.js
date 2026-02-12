const bcrypt = require('bcryptjs');
const Doctor = require('../models/doctor');

// GET /doctors?page=&limit=
// exports exports function so it can be used in other files
exports.getAll = async (req, res, next) => {
  try {
    // || number is default
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const skip = (page - 1) * limit;

    const [total, doctors] = await Promise.all([
      // total number of doctors (for frontend)
      Doctor.countDocuments(),
      Doctor.find()
        // exclude hash
        .select('-passwordHash')
        .skip(skip)
        .limit(limit)
        .sort({ createdAt: -1 })
    ]);

    res.json({
      page,
      limit,
      total,
      data: doctors
    });
  } catch (err) {
    next(err);
  }
};

// GET /doctors/:id
exports.getById = async (req, res, next) => {
  try {
    const doctor = await Doctor.findById(req.params.id).select('-passwordHash');
    if (!doctor) return res.status(404).json({ error: 'Doctor not found' });
    res.json(doctor);
  } catch (err) {
    next(err);
  }
};

// GET /doctors/specialty/:specialty
exports.getBySpecialty = async (req, res, next) => {
  try {
    const { specialty } = req.params;
    const doctors = await Doctor.find({ specialty })
      .select('-passwordHash')
      .sort({ name: 1 });
    res.json(doctors);
  } catch (err) {
    next(err);
  }
};

// PUT /doctors/:id
exports.update = async (req, res, next) => {
  try {
    const { id, role: requesterRole } = req.user;
    const updates = { ...req.body };

    // Only allow admin or the doctor themselves
    if (requesterRole !== 'admin' && id !== req.params.id) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    if (updates.password) {
      updates.passwordHash = await bcrypt.hash(updates.password, 10);
      delete updates.password;
    }

    const doctor = await Doctor.findByIdAndUpdate(
      req.params.id,
      updates,
      { new: true, runValidators: true }
    ).select('-passwordHash');

    if (!doctor) return res.status(404).json({ error: 'Doctor not found' });
    res.json(doctor);
  } catch (err) {
    next(err);
  }
};

// PATCH /doctors/:id/password
exports.changePassword = async (req, res, next) => {
  try {
    const { id: requesterId, role } = req.user;
    const targetId = req.params.id;

    // only admin or the doctor themselves
    if (role !== 'admin' && requesterId !== targetId) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    const { password } = req.body;
    if (!password) {
      return res.status(400).json({ error: 'New password is required' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const doctor = await Doctor.findByIdAndUpdate(targetId, { passwordHash });

    if (!doctor) return res.status(404).json({ error: 'Doctor not found' });
    res.json({ message: 'Password updated' });
  } catch (err) {
    next(err);
  }
};

// DELETE /doctors/:id
exports.remove = async (req, res, next) => {
  try {
    const { role: requesterRole } = req.user;
    // Only admin can delete
    if (requesterRole !== 'admin') {
      return res.status(403).json({ error: 'Forbidden' });
    }

    const doctor = await Doctor.findByIdAndDelete(req.params.id);
    if (!doctor) return res.status(404).json({ error: 'Doctor not found' });
    res.status(204).end();
  } catch (err) {
    next(err);
  }
};
