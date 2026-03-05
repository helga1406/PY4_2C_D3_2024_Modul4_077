import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logbook_app_077/features/logbook/log_controller.dart';
import 'package:logbook_app_077/features/logbook/models/log_model.dart';
import 'package:logbook_app_077/features/widgets/log_item_widget.dart';
import 'package:logbook_app_077/services/mongo_service.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;
  Future<List<LogModel>>? _logsFuture;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final Color _primaryPink = const Color.fromARGB(255, 158, 101, 140);
  final Color _inputGrey = const Color.fromARGB(255, 245, 245, 245);

  String _selectedCategory = "Pribadi";
  final List<String> _categories = ["Pribadi", "Pekerjaan", "Urgent"];

  @override
  void initState() {
    super.initState();
    _controller = LogController(username: widget.username);
    _fetchLogs();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _fetchLogs() {
    setState(() {
      _logsFuture = MongoService().getLogs(widget.username);
    });
  }

  // --- REFACTOR LOGIC DI BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Logbook: ${widget.username}",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: _primaryPink,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _confirmAction(
              title: "Konfirmasi Logout",
              content: "Apakah Anda yakin ingin keluar?",
              onConfirm: () => Navigator.of(context).pushReplacementNamed('/'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBarAndFilter(),
          Expanded(
            child: FutureBuilder<List<LogModel>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _buildErrorState(); 
                }

                final logs = snapshot.data ?? [];
                final filtered = _filterLogs(logs);

              if (logs.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async => _fetchLogs(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7, // Beri ruang agar Spacer bisa bekerja
                    child: _buildEmptyState(),
                  ),
                ),
              );
            }

                // 4. TAMPILAN DATA LIST
                return _buildLogList(filtered);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openLogDialog(),
        backgroundColor: _primaryPink,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
// --- WIDGET ERROR STATE  ---
  Widget _buildErrorState() {
    return Column(
      children: [
        const Spacer(flex: 3), 
        Icon(Icons.wifi_off_rounded, size: 100, color: Colors.grey[400]),
        const SizedBox(height: 20),
        const Text(
          "Yah, Koneksi Terputus!",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          "Gagal menghubungi MongoDB Atlas.\nPeriksa internet kamu ya.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 25),
        ElevatedButton.icon(
          onPressed: _fetchLogs,
          icon: const Icon(Icons.refresh),
          label: const Text("COBA LAGI"),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryPink,
            foregroundColor: Colors.white,
          ),
        ),
        const Spacer(flex:5),// Mendorong konten dari bawah
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : _primaryPink,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _closeDialog() {
    _titleController.clear();
    _contentController.clear();
    Navigator.pop(context);
  }

  void _showReadLogDialog(LogModel log) {
    String formattedDate;
    try {
      DateTime dt = DateTime.parse(log.timestamp);
      formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (e) {
      formattedDate = log.timestamp;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          log.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryPink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  log.category,
                  style: TextStyle(color: _primaryPink, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                log.description,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const Divider(height: 30),
              Text(
                "Dibuat pada: $formattedDate",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("TUTUP", style: TextStyle(color: _primaryPink, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openLogDialog({int? index, LogModel? log}) {
    final isEdit = index != null && log != null;
    if (isEdit) {
      _titleController.text = log.title;
      _contentController.text = log.description;
      _selectedCategory = log.category;
    } else {
      _titleController.clear();
      _contentController.clear();
      _selectedCategory = "Pribadi";
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEdit ? "Edit Catatan" : "Tambah Catatan",
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_titleController, "Judul"),
                const SizedBox(height: 10),
                _buildTextField(_contentController, "Isi catatan...", maxLines: 8),
                const SizedBox(height: 15),
                _buildCategoryDropdown(setDialogState),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: _closeDialog,
                  child: Text("BATAL", style: TextStyle(color: _primaryPink, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () => _handleSave(isEdit, log),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(isEdit ? "UPDATE" : "SIMPAN", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave(bool isEdit, LogModel? oldLog) async {
    final title = _titleController.text.trim();
    final desc = _contentController.text.trim();
    if (title.isEmpty) {
      _showSnackBar("Judul tidak boleh kosong!", isError: true);
      return;
    }
    try {
      final String formattedTime = DateTime.now().toString();
      final logData = LogModel(
        id: isEdit ? oldLog?.id : null,
        title: title,
        description: desc,
        timestamp: formattedTime,
        category: _selectedCategory,
      );
      if (isEdit) {
        await MongoService().updateLog(logData, widget.username);
        _showSnackBar("Berhasil diperbarui!");
      } else {
        await MongoService().insertLog(logData, widget.username);
        _showSnackBar("Berhasil disimpan!");
      }
      if (!mounted) return;
      _closeDialog();
      _fetchLogs();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Gagal terhubung. Pastikan internet aktif.", isError: true);
    }
  }

  Future<void> _confirmAction({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: TextStyle(color: _primaryPink)),
          ),
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text("Ya"),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: _inputGrey, borderRadius: BorderRadius.circular(8)),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none),
      ),
    );
  }

  Widget _buildCategoryDropdown(StateSetter setDialogState) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: "Kategori",
        filled: true,
        fillColor: _inputGrey,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
      items: _categories.map((String category) {
        return DropdownMenuItem(value: category, child: Text(category));
      }).toList(),
      onChanged: (String? newValue) {
        setDialogState(() => _selectedCategory = newValue!);
      },
    );
  }

  Widget _buildSearchBarAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _controller.searchLog(value)),
              decoration: InputDecoration(
                hintText: "Cari judul...",
                prefixIcon: Icon(Icons.search, color: _primaryPink),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: _primaryPink.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: _primaryPink, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildFilterDropdown(),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _primaryPink.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(25),
      ),
      child: DropdownButtonHideUnderline(
        child: ValueListenableBuilder<String>(
          valueListenable: _controller.selectedFilter,
          builder: (context, currentFilter, _) {
            return DropdownButton<String>(
              value: currentFilter,
              icon: Icon(Icons.filter_list_rounded, color: _primaryPink),
              style: TextStyle(color: _primaryPink, fontWeight: FontWeight.bold),
              items: ["Semua", "Pribadi", "Pekerjaan", "Urgent"]
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _controller.setFilterCategory(val));
              },
            );
          },
        ),
      ),
    );
  }

  List<LogModel> _filterLogs(List<LogModel> logs) {
    final search = _controller.searchQuery.value.toLowerCase();
    final filter = _controller.selectedFilter.value;
    return logs.where((log) {
      final matchesSearch = log.title.toLowerCase().contains(search);
      final matchesCat = filter == "Semua" || log.category == filter;
      return matchesSearch && matchesCat;
    }).toList();
  }

  Widget _buildEmptyState() {
    final bool isFiltering = _controller.searchQuery.value.isNotEmpty || 
                             _controller.selectedFilter.value != "Semua";
    return Column(
      children: [
        const Spacer(flex: 2),
        Icon(Icons.cloud_queue_rounded, size: 100, color: _primaryPink.withValues(alpha: 0.1)),
        const SizedBox(height: 20),
        Text(isFiltering ? "Tidak Ditemukan" : "Cloud Masih Kosong",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _primaryPink)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: Text(
            isFiltering ? "Catatan tidak ditemukan." : "Belum ada catatan. Ketuk + untuk menambah.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        const Spacer(flex: 3),
      ],
    );
  }

  Widget _buildLogList(List<LogModel> filtered) {
    return RefreshIndicator(
      onRefresh: () async => _fetchLogs(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final log = filtered[index];
          return Dismissible(
            key: Key(log.id?.oid ?? log.timestamp + log.title),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              bool delete = false;
              await _confirmAction(
                title: "Konfirmasi Hapus",
                content: "Hapus catatan ini?",
                onConfirm: () { delete = true; Navigator.pop(context); },
              );
              return delete;
            },
            onDismissed: (_) async {
              if (log.id != null) await MongoService().deleteLog(log.id!, widget.username);
              _showSnackBar("Catatan telah dihapus.");
              _fetchLogs();
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.redAccent,
              child: const Icon(Icons.delete_forever, color: Colors.white, size: 30),
            ),
            child: LogItemWidget(
              log: log,
              onTap: () => _showReadLogDialog(log),
              onEdit: () => _openLogDialog(index: index, log: log),
              onDelete: () => _confirmAction(
                title: "Konfirmasi Hapus",
                content: "Hapus catatan ini?",
                onConfirm: () async {
                  if (log.id != null) await MongoService().deleteLog(log.id!, widget.username);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _showSnackBar("Catatan telah dihapus.");
                  _fetchLogs();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}