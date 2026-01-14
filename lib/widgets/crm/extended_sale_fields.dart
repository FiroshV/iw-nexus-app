import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/sale_extended_details.dart';
import '../common/indian_phone_input.dart';

// ============= Proposer Details Section =============
class ProposerDetailsSection extends StatefulWidget {
  final ProposerDetails? initialData;
  final ValueChanged<ProposerDetails> onChanged;

  const ProposerDetailsSection({
    super.key,
    this.initialData,
    required this.onChanged,
  });

  @override
  State<ProposerDetailsSection> createState() => _ProposerDetailsSectionState();
}

class _ProposerDetailsSectionState extends State<ProposerDetailsSection> {
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  String? _selectedGender;
  DateTime? _selectedDOB;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.initialData?.fullName ?? '',
    );
    _emailController = TextEditingController(
      text: widget.initialData?.email ?? '',
    );
    _mobileController = TextEditingController(
      text: IndianPhoneInput.parseFromApi(widget.initialData?.mobileNumber),
    );
    _selectedGender = widget.initialData?.gender;
    _selectedDOB = widget.initialData?.dateOfBirth;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _updateData() {
    widget.onChanged(
      ProposerDetails(
        fullName: _fullNameController.text.isEmpty
            ? null
            : _fullNameController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        mobileNumber: _mobileController.text.isEmpty
            ? null
            : IndianPhoneInput.formatForApi(_mobileController.text),
        gender: _selectedGender,
        dateOfBirth: _selectedDOB,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Proposer Details'),
      initiallyExpanded: _isExpanded,
      onExpansionChanged: (value) => setState(() => _isExpanded = value),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter full name',
                  filled: true,
                  fillColor: const Color(0xFFFBF8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFECF0F1)),
                  ),
                ),
                onChanged: (_) => _updateData(),
              ),
              const SizedBox(height: 12),
              GenderSelector(
                selectedGender: _selectedGender,
                onChanged: (gender) {
                  setState(() => _selectedGender = gender);
                  _updateData();
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        _selectedDOB ??
                        DateTime.now().subtract(const Duration(days: 365 * 20)),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDOB = date);
                    _updateData();
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  hintText: 'Select date',
                  filled: true,
                  fillColor: const Color(0xFFFBF8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFECF0F1)),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(
                  text: _selectedDOB != null
                      ? DateFormat('dd MMM yyyy').format(_selectedDOB!)
                      : '',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter email',
                  filled: true,
                  fillColor: const Color(0xFFFBF8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFECF0F1)),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _updateData(),
              ),
              const SizedBox(height: 12),
              IndianPhoneInput(
                controller: _mobileController,
                labelText: 'Mobile Number',
                isRequired: false,
                onChanged: (_) => _updateData(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============= Nominee Card =============
class NomineeCard extends StatefulWidget {
  final Nominee nominee;
  final int index;
  final VoidCallback onRemove;
  final ValueChanged<Nominee> onChanged;

  const NomineeCard({
    super.key,
    required this.nominee,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<NomineeCard> createState() => _NomineeCardState();
}

class _NomineeCardState extends State<NomineeCard> {
  late TextEditingController _nameController;
  DateTime? _selectedDOB;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.nominee.name ?? '');
    _selectedDOB = widget.nominee.dateOfBirth;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateData() {
    widget.onChanged(
      Nominee(
        name: _nameController.text.isEmpty ? null : _nameController.text,
        dateOfBirth: _selectedDOB,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nominee ${widget.index}'),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Enter name',
                filled: true,
                fillColor: const Color(0xFFFBF8FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFECF0F1)),
                ),
              ),
              onChanged: (_) => _updateData(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      _selectedDOB ??
                      DateTime.now().subtract(const Duration(days: 365 * 20)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDOB = date);
                  _updateData();
                }
              },
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                hintText: 'Select date',
                filled: true,
                fillColor: const Color(0xFFFBF8FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFECF0F1)),
                ),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              controller: TextEditingController(
                text: _selectedDOB != null
                    ? DateFormat('dd MMM yyyy').format(_selectedDOB!)
                    : '',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============= Nominees Section =============
class NomineesSection extends StatefulWidget {
  final List<Nominee> nominees;
  final ValueChanged<List<Nominee>> onChanged;

  const NomineesSection({
    super.key,
    required this.nominees,
    required this.onChanged,
  });

  @override
  State<NomineesSection> createState() => _NomineesSectionState();
}

class _NomineesSectionState extends State<NomineesSection> {
  late List<Nominee> _nominees;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _nominees = List.from(widget.nominees);
  }

  void _addNominee() {
    if (_nominees.length < 3) {
      setState(() => _nominees.add(Nominee()));
      widget.onChanged(_nominees);
    }
  }

  void _removeNominee(int index) {
    setState(() => _nominees.removeAt(index));
    widget.onChanged(_nominees);
  }

  void _updateNominee(int index, Nominee nominee) {
    setState(() => _nominees[index] = nominee);
    widget.onChanged(_nominees);
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('Nominees (${_nominees.length}/3)'),
      initiallyExpanded: _isExpanded,
      onExpansionChanged: (value) => setState(() => _isExpanded = value),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              if (_nominees.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No nominees added',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              else
                ..._nominees.asMap().entries.map((entry) {
                  return NomineeCard(
                    nominee: entry.value,
                    index: entry.key + 1,
                    onRemove: () => _removeNominee(entry.key),
                    onChanged: (nominee) => _updateNominee(entry.key, nominee),
                  );
                }),
              if (_nominees.length < 3)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addNominee,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Add Nominee',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0071bf),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============= Insured Person Card =============
class InsuredPersonCard extends StatefulWidget {
  final InsuredPerson person;
  final int index;
  final VoidCallback onRemove;
  final ValueChanged<InsuredPerson> onChanged;

  const InsuredPersonCard({
    super.key,
    required this.person,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<InsuredPersonCard> createState() => _InsuredPersonCardState();
}

class _InsuredPersonCardState extends State<InsuredPersonCard> {
  late TextEditingController _fullNameController;
  late TextEditingController _pedController;
  late TextEditingController _medicationController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  String? _selectedGender;
  DateTime? _selectedDOB;
  String _heightUnit = 'cm';
  String _weightUnit = 'kg';

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.person.fullName ?? '',
    );
    _pedController = TextEditingController(
      text: widget.person.preExistingDiseases ?? '',
    );
    _medicationController = TextEditingController(
      text: widget.person.medicationDetails ?? '',
    );
    _heightController = TextEditingController(
      text: widget.person.height?.value?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.person.weight?.value?.toString() ?? '',
    );
    _selectedGender = widget.person.gender;
    _selectedDOB = widget.person.dateOfBirth;
    _heightUnit = widget.person.height?.unit ?? 'cm';
    _weightUnit = widget.person.weight?.unit ?? 'kg';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _pedController.dispose();
    _medicationController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _updateData() {
    widget.onChanged(
      InsuredPerson(
        fullName: _fullNameController.text.isEmpty
            ? null
            : _fullNameController.text,
        gender: _selectedGender,
        dateOfBirth: _selectedDOB,
        height: _heightController.text.isEmpty
            ? null
            : HeightWeight(
                value: double.tryParse(_heightController.text),
                unit: _heightUnit,
              ),
        weight: _weightController.text.isEmpty
            ? null
            : HeightWeight(
                value: double.tryParse(_weightController.text),
                unit: _weightUnit,
              ),
        preExistingDiseases: _pedController.text.isEmpty
            ? null
            : _pedController.text,
        medicationDetails: _medicationController.text.isEmpty
            ? null
            : _medicationController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Insured Person ${widget.index}'),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter full name',
                filled: true,
                fillColor: const Color(0xFFFBF8FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFECF0F1)),
                ),
              ),
              onChanged: (_) => _updateData(),
            ),
            const SizedBox(height: 12),
            GenderSelector(
              selectedGender: _selectedGender,
              onChanged: (gender) {
                setState(() => _selectedGender = gender);
                _updateData();
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      _selectedDOB ??
                      DateTime.now().subtract(const Duration(days: 365 * 20)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDOB = date);
                  _updateData();
                }
              },
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                hintText: 'Select date',
                filled: true,
                fillColor: const Color(0xFFFBF8FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFECF0F1)),
                ),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              controller: TextEditingController(
                text: _selectedDOB != null
                    ? DateFormat('dd MMM yyyy').format(_selectedDOB!)
                    : '',
              ),
            ),
            const SizedBox(height: 12),
            HeightWeightInput(
              heightValue: double.tryParse(_heightController.text),
              heightUnit: _heightUnit,
              weightValue: double.tryParse(_weightController.text),
              weightUnit: _weightUnit,
              onHeightChanged: (value, unit) {
                _heightController.text = value ?? '';
                _heightUnit = unit;
                _updateData();
              },
              onWeightChanged: (value, unit) {
                _weightController.text = value ?? '';
                _weightUnit = unit;
                _updateData();
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pedController,
              decoration: InputDecoration(
                labelText: 'Pre-existing Diseases (optional)',
                hintText: 'List any pre-existing diseases',
                filled: true,
                fillColor: const Color(0xFFFBF8FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFECF0F1)),
                ),
              ),
              maxLines: 2,
              onChanged: (_) => _updateData(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _medicationController,
              decoration: InputDecoration(
                labelText: 'Medication Details (optional)',
                hintText: 'List any medications',
                filled: true,
                fillColor: const Color(0xFFFBF8FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFECF0F1)),
                ),
              ),
              maxLines: 2,
              onChanged: (_) => _updateData(),
            ),
          ],
        ),
      ),
    );
  }
}

// ============= Insured Persons Section =============
class InsuredPersonsSection extends StatefulWidget {
  final List<InsuredPerson> insuredPersons;
  final ValueChanged<List<InsuredPerson>> onChanged;

  const InsuredPersonsSection({
    super.key,
    required this.insuredPersons,
    required this.onChanged,
  });

  @override
  State<InsuredPersonsSection> createState() => _InsuredPersonsSectionState();
}

class _InsuredPersonsSectionState extends State<InsuredPersonsSection> {
  late List<InsuredPerson> _persons;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _persons = List.from(widget.insuredPersons);
  }

  void _addPerson() {
    setState(() => _persons.add(InsuredPerson()));
    widget.onChanged(_persons);
  }

  void _removePerson(int index) {
    setState(() => _persons.removeAt(index));
    widget.onChanged(_persons);
  }

  void _updatePerson(int index, InsuredPerson person) {
    setState(() => _persons[index] = person);
    widget.onChanged(_persons);
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('Insured Persons (${_persons.length})'),
      initiallyExpanded: _isExpanded,
      onExpansionChanged: (value) => setState(() => _isExpanded = value),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              if (_persons.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'No insured persons added',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              else
                ..._persons.asMap().entries.map((entry) {
                  return InsuredPersonCard(
                    person: entry.value,
                    index: entry.key + 1,
                    onRemove: () => _removePerson(entry.key),
                    onChanged: (person) => _updatePerson(entry.key, person),
                  );
                }),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addPerson,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add Insured Person',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0071bf),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============= Gender Selector =============
class GenderSelector extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String?> onChanged;

  const GenderSelector({
    super.key,
    this.selectedGender,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender',
        filled: true,
        fillColor: const Color(0xFFFBF8FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFECF0F1)),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'male', child: Text('Male')),
        DropdownMenuItem(value: 'female', child: Text('Female')),
      ],
      onChanged: onChanged,
    );
  }
}

// ============= Height/Weight Input =============
class HeightWeightInput extends StatelessWidget {
  final double? heightValue;
  final String heightUnit;
  final double? weightValue;
  final String weightUnit;
  final Function(String?, String) onHeightChanged;
  final Function(String?, String) onWeightChanged;

  const HeightWeightInput({
    super.key,
    this.heightValue,
    required this.heightUnit,
    this.weightValue,
    required this.weightUnit,
    required this.onHeightChanged,
    required this.onWeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: heightValue?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: 'Height',
                  filled: true,
                  fillColor: const Color(0xFFFBF8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFECF0F1)),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => onHeightChanged(value, heightUnit),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: heightUnit,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFFBF8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFECF0F1)),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'cm', child: Text('cm')),
                  DropdownMenuItem(value: 'feet', child: Text('feet')),
                ],
                onChanged: (value) => onHeightChanged(
                  heightValue?.toString(),
                  value ?? heightUnit,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: weightValue?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: 'Weight',
                  filled: true,
                  fillColor: const Color(0xFFFBF8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFECF0F1)),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => onWeightChanged(value, weightUnit),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: weightUnit,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFFBF8FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFECF0F1)),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'lbs', child: Text('lbs')),
                ],
                onChanged: (value) => onWeightChanged(
                  weightValue?.toString(),
                  value ?? weightUnit,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
