import 'dart:collection';

class ChangeStack {
  /// Changes to keep track of
  ChangeStack({this.limit});

  /// Limit changes to store in the history
  int? limit;

  final Queue<List<Change>> _history = ListQueue();
  final Queue<List<Change>> _redos = ListQueue();

  /// Can redo the previous change
  bool get canRedo => _redos.isNotEmpty;

  /// Can undo the previous change
  bool get canUndo => _history.isNotEmpty;

  ///Will return the last change
  List<Change>? get current {
    try {
      //This can throw an error, if theres no last element
      _history.last;
    } catch (e) {
      //Thats why we should return null in that case
      return null;
    }
  }

  ///Get Change List length
  int get length => _history.length;

  /// Add New Change and Clear Redo Stack
  void add<T>(Change<T> change) {
    change.execute();
    _history.addLast([change]);
    _moveForward();
  }

  void _moveForward() {
    _redos.clear();

    if (limit != null && _history.length > limit! + 1) {
      _history.removeFirst();
    }
  }

  /// Add New Group of Changes and Clear Redo Stack
  void addGroup<T>(List<Change<T>> changes) {
    _applyChanges(changes);
    _history.addLast(changes);
    _moveForward();
  }

  void _applyChanges(List<Change> changes) {
    for (final change in changes) {
      change.execute();
    }
  }

  /// Clear Undo History
  @deprecated
  void clear() => clearHistory();

  /// Clear Undo History
  void clearHistory() {
    _history.clear();
    _redos.clear();
  }

  /// Redo Previous Undo
  void redo() {
    if (canRedo) {
      final changes = _redos.removeFirst();
      _applyChanges(changes);
      _history.addLast(changes);
    }
  }

  /// Undo Last Change
  void undo() {
    if (canUndo) {
      final changes = _history.removeLast();
      //Changes need to be reversed,
      //because you should start from the last item (i.e. the biggest index) in a group-change
      for (final change in changes.reversed) {
        change.undo();
      }
      _redos.addFirst(changes);
    }
  }
}

class Change<T> {
  Change(
    this._oldValue,
    this._execute(),
    this._undo(dynamic oldValue), {
    this.id,
    this.description = '',
  });

  final Object? id;

  final String description;

  final void Function() _execute;
  final dynamic _oldValue;

  final void Function(dynamic oldValue) _undo;

  void execute() {
    _execute();
  }

  void undo() {
    _undo(_oldValue);
  }

  Change copyWith({dynamic id, String? description}) {
    return Change(
      this._oldValue,
      this._execute,
      this._undo,
      id: id,
      description: description ?? '',
    );
  }
}
