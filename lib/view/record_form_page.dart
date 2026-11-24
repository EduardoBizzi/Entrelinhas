import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../controller/library_controller.dart';
import '../database/model/reading_record.dart';
import '../service/location_service.dart';
import '../service/photo_service.dart';
import '../utils/error_message.dart';
import '../utils/validators.dart';

class RecordFormPage extends StatefulWidget {
  const RecordFormPage({
    super.key,
    required this.controller,
    required this.record,
    this.editing = false,
    this.recoveredImage,
  });
  final LibraryController controller;
  final ReadingRecord record;
  final bool editing;
  final String? recoveredImage;
  @override
  State<RecordFormPage> createState() => _RecordFormPageState();
}

class _RecordFormPageState extends State<RecordFormPage> {
  final _form = GlobalKey<FormState>();
  final _photos = PhotoService();
  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _description;
  late final TextEditingController _pages;
  late final TextEditingController _total;
  late final TextEditingController _place;
  late DateTime _date;
  late ReadingStatus _status;
  double? _latitude;
  double? _longitude;
  String? _photo;
  bool _removePhoto = false;
  bool _busy = false;
  bool _locating = false;
  bool _picking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _title = TextEditingController(text: record.title);
    _author = TextEditingController(text: record.author);
    _description = TextEditingController(text: record.description);
    _pages = TextEditingController(text: '${record.pages}');
    _total = TextEditingController(text: '${record.totalPages}');
    _place = TextEditingController(text: record.place);
    _date = record.eventAt;
    _status = record.status;
    _latitude = record.latitude;
    _longitude = record.longitude;
    _photo = widget.recoveredImage;
    if (_photo == null) _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final photo = await _photos.existing(
      widget.record.userId,
      widget.record.id,
    );
    if (mounted) setState(() => _photo = photo);
  }

  ReadingRecord _draft() => widget.record.copyWith(
    title: _title.text.trim(),
    author: _author.text.trim(),
    description: _description.text.trim(),
    eventAt: _date,
    status: _status,
    pages: int.tryParse(_pages.text) ?? 0,
    totalPages: int.tryParse(_total.text) ?? 0,
    latitude: _latitude,
    longitude: _longitude,
    clearLocation: _latitude == null,
    place: _place.text.trim(),
  );

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (!mounted) return;
    setState(
      () => _date = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _date.hour,
        time?.minute ?? _date.minute,
      ),
    );
  }

  Future<void> _locate() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar local de leitura?'),
        content: const Text(
          'O GPS será usado somente agora, para associar latitude e longitude a este livro. A localização será salva na sua conta. Você também pode continuar sem ela.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usar localização'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final position = await LocationService().currentPosition();
      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _picking = true);
    try {
      final photo = await _photos.pick(source, _draft());
      if (mounted && photo != null) {
        setState(() {
          _photo = photo;
          _removePhoto = false;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final record = _draft();
      if (_photo != null && !_removePhoto) {
        await _photos.persist(record.userId, record.id, _photo!);
      }
      await widget.controller.save(record);
      if (_removePhoto) await _photos.remove(record.userId, record.id);
      if (mounted) Navigator.pop(context, record.id);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _number(String? text) {
    final value = int.tryParse(text ?? '');
    if (value == null || value < 0 || value > 100000) {
      return 'Use um número de 0 a 100000.';
    }
    return null;
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _author,
      _description,
      _pages,
      _total,
      _place,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.editing ? 'Editar livro' : 'Adicionar à biblioteca'),
    ),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Uma história na sua estante',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cadastre o livro e escolha a data da sua próxima leitura.',
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: const ValueKey('record_title'),
                controller: _title,
                maxLength: 160,
                decoration: const InputDecoration(
                  labelText: 'Título do livro *',
                ),
                validator: (value) =>
                    Validators.requiredText(value, field: 'o título'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('record_author'),
                controller: _author,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Autor *'),
                validator: (value) =>
                    Validators.requiredText(value, field: 'o autor'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('record_description'),
                controller: _description,
                maxLength: 2000,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Descrição ou anotações *',
                  alignLabelWithHint: true,
                ),
                validator: (value) =>
                    Validators.requiredText(value, field: 'a descrição'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ReadingStatus>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Situação da leitura',
                ),
                items: ReadingStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _busy ? null : _chooseDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(DateFormat('dd/MM/yyyy • HH:mm').format(_date)),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pages,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Páginas lidas',
                      ),
                      validator: (value) {
                        final basic = _number(value);
                        if (basic != null) return basic;
                        final total = int.tryParse(_total.text) ?? 0;
                        return total > 0 && int.parse(value!) > total
                            ? 'Supera o total de páginas.'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _total,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total de páginas',
                        helperText: '0 se não souber',
                      ),
                      validator: _number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const Text(
                'Lugar de leitura',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _place,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Nome do local (opcional)',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              if (_latitude != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.my_location),
                    title: Text('Latitude: ${_latitude!.toStringAsFixed(6)}'),
                    subtitle: Text(
                      'Longitude: ${_longitude!.toStringAsFixed(6)}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Remover coordenadas',
                      onPressed: () => setState(() {
                        _latitude = null;
                        _longitude = null;
                      }),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _locating || _busy ? null : _locate,
                icon: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.gps_fixed),
                label: Text(
                  _locating ? 'Obtendo posição...' : 'Obter localização atual',
                ),
              ),
              Wrap(
                children: [
                  TextButton(
                    onPressed: () => Geolocator.openLocationSettings(),
                    child: const Text('Configurar GPS'),
                  ),
                  TextButton(
                    onPressed: () => Geolocator.openAppSettings(),
                    child: const Text('Permissões do aplicativo'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Uma imagem para lembrar',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Opcional. Uma foto por livro, até 10 fotos de 5 MB por conta neste aparelho. As fotos não são enviadas à nuvem.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              if (_photo != null && !_removePhoto) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(_photo!),
                    height: 190,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Text(
                      'Não foi possível abrir esta foto. Selecione outra.',
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _photo = null;
                    _removePhoto = true;
                  }),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover foto'),
                ),
              ],
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _picking || _busy
                        ? null
                        : () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeria'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _picking || _busy
                        ? null
                        : () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Câmera'),
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              FilledButton.icon(
                key: const ValueKey('record_save'),
                onPressed: _busy || _locating || _picking ? null : _save,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_busy ? 'Salvando...' : 'Salvar na biblioteca'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
