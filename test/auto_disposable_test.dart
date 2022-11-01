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

import 'package:auto_disposable/auto_disposable.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  group(AutoDisposerMixin, () {
    test('is not disposed initially', () {
      expect(AutoDisposer().isDisposed, isFalse);
    });

    test('does not throw when calling checkDisposed() initially', () {
      expect(() => AutoDisposer().checkDisposed(), returnsNormally);
    });

    test('returns true from isDisposed after calling dispose', () {
      expect((AutoDisposer()..dispose()).isDisposed, isTrue);
    });

    test('throws in checkDisposed() after calling dispose', () {
      expect(
        () => (AutoDisposer()..dispose()).checkDisposed(),
        throwsStateError,
      );
    });

    test('does not call Disposable.dispose() if not disposed of', () {
      final disposable = MockDisposable();
      AutoDisposer().autoDispose(disposable);
      verifyNever(disposable.dispose());
    });

    test('does not call custom disposal function if not disposed of', () {
      final disposable = MockDisposable();
      AutoDisposer().autoDisposeCustom(disposable.dispose);
      verifyNever(disposable.dispose());
    });

    test('calls added Disposable.dispose()', () {
      final disposable = MockDisposable();
      AutoDisposer()
        ..autoDispose(disposable)
        ..dispose();
      verify(disposable.dispose());
      verifyNoMoreInteractions(disposable);
    });

    test('calls added custom disposal function', () {
      final disposable = MockDisposable();
      AutoDisposer()
        ..autoDisposeCustom(disposable.dispose)
        ..dispose();
      verify(disposable.dispose());
      verifyNoMoreInteractions(disposable);
    });

    test('called disposers in reverse order', () {
      final disposable1 = MockDisposable();
      final disposable2 = MockDisposable();
      AutoDisposer()
        ..autoDispose(disposable1)
        ..autoDisposeCustom(disposable2.dispose)
        ..dispose();
      verifyInOrder([
        disposable2.dispose(),
        disposable1.dispose(),
      ]);
      verifyNoMoreInteractions(disposable1);
      verifyNoMoreInteractions(disposable2);
    });

    test('prevents re-entrant', () {
      final disposer = AutoDisposer();
      // Adds a disposer function that recursively calls the `disposer()`
      // method. If re-entrant is allowed, this creates a dead loop.
      disposer.autoDisposeCustom(() => disposer.dispose());
      disposer.dispose();
    });
  });
}

class AutoDisposer with AutoDisposerMixin {}

class MockDisposable extends Mock implements Disposable {}
