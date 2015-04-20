// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.utils.frappe;

import 'dart:async';
import 'package:frappe/frappe.dart';

class ControllableEventStream<T> {
  final StreamController<T> controller;
  EventStream<T> _eventStream;
  EventStream<T> get eventStream => _eventStream;

  void add(T value) => controller.add(value);

  ControllableEventStream._internal(this.controller) {
    _eventStream = new EventStream(controller.stream);
  }

  ControllableEventStream.std()
      : this._internal(new StreamController.broadcast());
}

class ControllableProperty<T> {
  final ControllableEventStream<T> controllable;
  final Property<T> property;
  Property<T> get distinctProperty => property.distinct();

  void set value(T v) {
//    print('==========$v');
    controllable.controller.add(v);
  }

  ControllableProperty._(
      T initialValue, ControllableEventStream<T> controllable)
      : this.controllable = controllable,
        this.property = initialValue != null
            ? new Property.fromStreamWithInitialValue(
                initialValue, controllable.eventStream)
            : new Property.fromStream(controllable.eventStream);

  ControllableProperty([T initialValue])
      : this._(initialValue, new ControllableEventStream.std());
}
