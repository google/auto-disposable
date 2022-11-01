// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:meta/meta.dart';
import 'package:quiver/check.dart';

/// Interface to classes that can be disposed.
///
/// When used with package provider, we have a good pattern to manage the
/// lifecycle of top-level models. For example:
///
/// ```dart
/// class FooModel implements Disposable {...}
///
/// Provider<FooModel>(
///   builder: (_) => FooModel(),
///   dispose: (_, value) => value.dispose(),
/// )
/// ```
abstract class Disposable {
  /// Disposes the object.
  void dispose();
}

/// A mixin that supports tracking the disposal state for [Disposable]s.
///
/// This mixin automatically manages the disposal states for added [Disposable]s
/// and custom disposers.
///
/// Note on disposal order: the disposables/custom disposers are called in the
/// REVERSE order of declaration.
///
/// Sample:
/// ```dart
/// class Foo with AutoDisposerMixin {
///   final _controller = StreamController<int>();
///   Stream<int> _stream;
///
///   Stream<int> get stream {
///     checkDisposed();
///     return _stream;
///   }
///
///   void add(int value) {
///     checkDisposed();
///     _controller.add(value);
///   }
///
///   StreamSubscription<int> _listener;
///
///   Foo() {
///     _stream = _controller.stream.asBroadcastStream();
///     _listener = stream.listen(print);
///     autoDisposeCustom(_controller.close);
///     autoDisposeCustom(_listener.cancel);
///   }
/// }
/// ```
///
/// In the above example, `_listener.cancel` is called first, followed by
/// `_controller.close`.
mixin AutoDisposerMixin implements Disposable {
  /// Returns true if this object has been disposed.
  bool get isDisposed => _isDisposed;
  bool _isDisposed = false;

  /// Functions to call at disposal time.
  final _disposers = <void Function()>[];

  /// Throws a `StateError` when this object has been disposed.
  @protected
  @visibleForTesting
  void checkDisposed() {
    checkState(!_isDisposed, message: 'Object [$this] has been disposed!');
  }

  /// Adds [disposable] to the auto disposers list.
  ///
  /// The `dispose()` method of [disposable] will be called automatically when
  /// this object is disposed of.
  @protected
  @visibleForTesting
  void autoDispose(Disposable disposable) => _disposers.add(disposable.dispose);

  /// Adds [disposer] to the auto disposers list.
  ///
  /// Function [disposer] will be called automatically when this object is
  /// disposed of.
  @protected
  @visibleForTesting
  void autoDisposeCustom(void Function() disposer) => _disposers.add(disposer);

  @mustCallSuper
  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      while (_disposers.isNotEmpty) {
        _disposers.removeLast()();
      }
    }
  }
}
