import 'package:flutter/material.dart';
import 'package:logbook_app_077/features/logbook/log_controller.dart';
import 'package:logbook_app_077/features/logbook/models/log_model.dart';
import 'package:logbook_app_077/features/widgets/log_item_widget.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;

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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _showReadLogDialog(LogModel log) {
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
                  style: TextStyle(
                    color: _primaryPink, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                log.description,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const Divider(height: 30),
              Text(
                "Dibuat pada: ${log.timestamp}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "TUTUP", 
              style: TextStyle(color: _primaryPink, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isEdit ? "Edit Catatan" : "Tambah Catatan",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _inputGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: "Judul",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _inputGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _contentController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: "Isi catatan...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory, 
                  dropdownColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: "Kategori",
                    filled: true,
                    fillColor: _inputGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setDialogState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => _closeDialog(),
                  child: Text(
                    "BATAL",
                    style: TextStyle(
                      color: _primaryPink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = _titleController.text.trim();
                    final desc = _contentController.text.trim();
                    if (title.isEmpty) {
                      _showSnackBar("Judul tidak boleh kosong!", isError: true);
                      return;
                    }
                    if (isEdit) {
                      _controller.updateLog(
                        index,
                        title,
                        desc,
                        _selectedCategory,
                      );
                    } else {
                      _controller.addLog(title, desc, _selectedCategory);
                    }
                    _closeDialog();
                    _showSnackBar(
                      isEdit ? "Berhasil diperbarui!" : "Berhasil disimpan!",
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    isEdit ? "UPDATE" : "SIMPAN",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _closeDialog() {
    _titleController.clear();
    _contentController.clear();
    Navigator.pop(context);
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text("Ya"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, 
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Logbook: ${widget.username}",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: _primaryPink,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => _controller.searchLog(value),
                    decoration: InputDecoration(
                      hintText: "Cari judul...",
                      prefixIcon: Icon(Icons.search, color: _primaryPink),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(
                          color: _primaryPink.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: _primaryPink, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _primaryPink.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: ValueListenableBuilder<String>(
                      valueListenable: _controller.selectedFilter,
                      builder: (context, currentFilter, _) {
                        return DropdownButton<String>(
                          value: currentFilter,
                          icon: Icon(Icons.filter_list_rounded, color: _primaryPink),
                          dropdownColor: Colors.white,
                          style: TextStyle(color: _primaryPink, fontWeight: FontWeight.bold),
                          items: ["Semua", "Pribadi", "Pekerjaan", "Urgent"]
                              .map((String category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              _controller.setFilterCategory(newValue);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.filteredLogs,
              builder: (context, currentLogs, _) {
                final String currentSearch = _controller.searchQuery.value;
                final String currentFilter = _controller.selectedFilter.value;

                if (currentLogs.isEmpty) {
                  final bool isSearchingOrFiltering = currentSearch.isNotEmpty || currentFilter != "Semua";
                  
                  return Column(
                    children: [
                      const Spacer(flex: 2),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 25,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: Image.asset(
                                  "assets/images/icon.jpeg",
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.note_alt,
                                      size: 100,
                                      color: _primaryPink,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              isSearchingOrFiltering ? "Tidak Ditemukan" : "Logbook Masih Kosong",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _primaryPink,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                isSearchingOrFiltering
                                    ? "Catatan dengan kriteria tersebut tidak ditemukan."
                                    : "Ketuk tombol + untuk mulai mencatat hari ini.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600], fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 3),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: currentLogs.length,
                  itemBuilder: (context, index) {
                    final log = currentLogs[index];
                    
                    // TAMBAHAN: DISMISSIBLE UNTUK SWIPE DELETE
                    return Dismissible(
                      key: Key(log.timestamp + log.title), 
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        bool delete = false;
                        await _confirmAction(
                          title: "Konfirmasi Hapus",
                          content: "Hapus catatan ini?",
                          onConfirm: () {
                            delete = true;
                            Navigator.pop(context);
                          },
                        );
                        return delete;
                      },
                      onDismissed: (direction) {
                        _controller.removeLog(index);
                        _showSnackBar("Catatan telah dihapus.");
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        margin: const EdgeInsets.symmetric(vertical: 8),
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
                          onConfirm: () {
                            _controller.removeLog(index);
                            Navigator.pop(context);
                            _showSnackBar("Catatan telah dihapus.");
                          },
                        ),
                      ),
                    );
                  },
                );
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
}