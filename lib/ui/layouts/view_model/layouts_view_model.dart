import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/repositories/layout_repository.dart';

class LayoutsViewModel extends ChangeNotifier {
  LayoutsViewModel({required LayoutRepository repository})
    : _repository = repository {
    refresh();
  }

  final LayoutRepository _repository;

  List<JournalLayout> _layouts = const [];
  String? _defaultId;

  List<JournalLayout> get layouts => _layouts;
  String? get defaultLayoutId => _defaultId;

  void refresh() {
    _layouts = _repository.getAll();
    _defaultId = _repository.getDefault()?.id;
    debugPrint(
      '[LayoutsVM] refresh -> ${_layouts.length} layouts, default=$_defaultId',
    );
    notifyListeners();
  }

  Future<void> setDefault(String id) async {
    debugPrint('[LayoutsVM] setDefault $id');
    await _repository.setDefault(id);
    refresh();
  }

  Future<void> delete(String id) async {
    debugPrint('[LayoutsVM] delete $id');
    await _repository.delete(id);
    refresh();
  }
}
