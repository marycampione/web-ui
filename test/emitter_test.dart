// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * These are not quite unit tests, since we build on top of the analyzer and the
 * html5parser to build the input for each test.
 */
library emitter_test;

import 'package:html5lib/dom.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'package:web_components/src/analyzer.dart';
import 'package:web_components/src/emitters.dart';
import 'package:web_components/src/html5_utils.dart';
import 'package:web_components/src/info.dart';
import 'package:web_components/src/file_system/path.dart' show Path;
import 'testing.dart';


main() {
  useVmConfiguration();
  useMockMessages();
  group('emit element field', () {
    group('declaration', () {
      test('no data binding', () {
        var elem = parseSubtree('<div></div>');
        var code = _declarationsRecursive(analyzeElement(elem));
        expect(code, equals(''));
      });

      test('id only, no data binding', () {
        var elem = parseSubtree('<div id="one"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_declarations(emitter),
            equals('autogenerated.DivElement _one;'));
      });

      test('action with no id', () {
        var elem = parseSubtree('<div data-action="foo:bar"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_declarations(emitter),
            equals('autogenerated.DivElement __e0;'));
      });

      test('action with id', () {
        var elem = parseSubtree('<div id="my-id" data-action="foo:bar"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_declarations(emitter),
            equals('autogenerated.DivElement _myId;'));
      });

      test('1 way binding with no id', () {
        var elem = parseSubtree('<div class="{{bar}}"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_declarations(emitter),
            equals('autogenerated.DivElement __e0;'));
      });

      test('1 way binding with id', () {
        var elem = parseSubtree('<div id="my-id" class="{{bar}}"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_declarations(emitter),
            equals('autogenerated.DivElement _myId;'));
      });

      test('2 way binding with no id', () {
        var elem = parseSubtree('<input data-bind="value:bar"></input>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_declarations(emitter),
            equals('autogenerated.InputElement __e0;'));
      });

      test('2 way binding with id', () {
        var elem = parseSubtree(
          '<input id="my-id" data-bind="value:bar"></input>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_declarations(emitter),
            equals('autogenerated.InputElement _myId;'));
      });
    });

    group('created', () {
      test('no data binding', () {
        var elem = parseSubtree('<div></div>');
        var code = _createdRecursive(analyzeElement(elem));
        expect(code, equals(''));
      });

      test('id only, no data binding', () {
        var elem = parseSubtree('<div id="one"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_created(emitter), equals("_one = _root.query('#one');"));
      });

      test('action with no id', () {
        var elem = parseSubtree('<div data-action="foo:bar"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_created(emitter), equals("__e0 = _root.query('#__e-0');"));
      });

      test('action with id', () {
        var elem = parseSubtree('<div id="my-id" data-action="foo:bar"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_created(emitter), equals("_myId = _root.query('#my-id');"));
      });

      test('1 way binding with no id', () {
        var elem = parseSubtree('<div class="{{bar}}"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_created(emitter), equals("__e0 = _root.query('#__e-0');"));
      });

      test('1 way binding with id', () {
        var elem = parseSubtree('<div id="my-id" class="{{bar}}"></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_created(emitter), equals("_myId = _root.query('#my-id');"));
      });

      test('2 way binding with no id', () {
        var elem = parseSubtree('<input data-bind="value:bar"></input>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_created(emitter), equals("__e0 = _root.query('#__e-0');"));
      });

      test('2 way binding with id', () {
        var elem = parseSubtree(
          '<input id="my-id" data-bind="value:bar"></input>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_created(emitter), equals("_myId = _root.query('#my-id');"));
      });
    });

    group('type', () {
      htmlElementNames.forEach((tag, className) {
        // Skip script and body tags, we don't create fields for them.
        if (tag == 'script' || tag == 'body') return;

        test('$tag -> $className', () {
          var elem = new Element(tag)..attributes['class'] = "{{bar}}";
          var emitter = new ElementFieldEmitter(analyzeElement(elem));
          expect(_declarations(emitter),
              equals('autogenerated.$className __e0;'));
        });
      });
    });
  });

  group('emit event listeners', () {
    test('declaration for action', () {
      var elem = parseSubtree('<div data-action="foo:bar"></div>');
      var emitter = new EventListenerEmitter(analyzeElement(elem));
      expect(_declarations(emitter), equals(
          'autogenerated.EventListener _listener__e0_foo_1;'));
    });

    test('declaration for input value data-bind', () {
      var elem = parseSubtree('<input data-bind="value:bar"></input>');
      var emitter = new EventListenerEmitter(analyzeElement(elem));
      expect(_declarations(emitter),
        equals('autogenerated.EventListener _listener__e0_input_1;'));
    });

    test('created', () {
      var elem = parseSubtree('<div data-action="foo:bar"></div>');
      var emitter = new EventListenerEmitter(analyzeElement(elem));
      expect(_created(emitter), equals(''));
    });

    test('inserted', () {
      var elem = parseSubtree('<div data-action="foo:bar"></div>');
      var emitter = new EventListenerEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '_listener__e0_foo_1 = (e) { bar(e); autogenerated.dispatch(); }; '
          '__e0.on.foo.add(_listener__e0_foo_1);'));
    });

    test('inserted for input value data bind', () {
      var elem = parseSubtree('<input data-bind="value:bar"></input>');
      var emitter = new EventListenerEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '_listener__e0_input_1 = (e) { bar = __e0.value; '
          'autogenerated.dispatch(); }; '
          '__e0.on.input.add(_listener__e0_input_1);'));
    });

    test('removed', () {
      var elem = parseSubtree('<div data-action="foo:bar"></div>');
      var emitter = new EventListenerEmitter(analyzeElement(elem));
      expect(_removed(emitter), equalsIgnoringWhitespace(
          '__e0.on.foo.remove(_listener__e0_foo_1); '
          '_listener__e0_foo_1 = null;'));
    });
  });

  group('emit data binding watchers', () {
    test('declaration', () {
      var elem = parseSubtree('<div foo="{{bar}}"></div>');
      var emitter = new DataBindingEmitter(analyzeElement(elem));
      expect(_declarations(emitter),
        equals('autogenerated.WatcherDisposer _stopWatcher__e0_1;'));
    });

    test('created', () {
      var elem = parseSubtree('<div foo="{{bar}}"></div>');
      var emitter = new DataBindingEmitter(analyzeElement(elem));
      expect(_created(emitter), equals(''));
    });

    test('inserted for attribute', () {
      var elem = parseSubtree('<div foo="{{bar}}"></div>');
      var emitter = new DataBindingEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '_stopWatcher__e0_1 = autogenerated.watchAndInvoke(() => '
          'bar, (e) { __e0.attributes["foo"] = e.newValue; });'));
    });

    test('inserted for 1-way binding with dom accessor', () {
      var elem = parseSubtree('<input value="{{bar}}">');
      var emitter = new DataBindingEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '_stopWatcher__e0_1 = autogenerated.watchAndInvoke(() => bar, (e) { '
          '__e0.value = e.newValue; });'));
    });

    test('inserted for 2-way binding with dom accessor', () {
      var elem = parseSubtree('<input data-bind="value:bar">');
      var emitter = new DataBindingEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '_stopWatcher__e0_1 = autogenerated.watchAndInvoke(() => bar, (e) { '
          '__e0.value = e.newValue; });'));
    });

    test('inserted for data- attribute', () {
      var elem = parseSubtree('<div data-foo="{{bar}}"></div>');
      var emitter = new DataBindingEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '_stopWatcher__e0_1 = autogenerated.watchAndInvoke(() => bar, (e) { '
          '__e0.attributes["data-foo"] = e.newValue; });'));
    });

    test('inserted for content', () {
      var elem = parseSubtree('<div>fo{{bar}}o</div>');
      var emitter = new DataBindingEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          "_stopWatcher__e0_1 = autogenerated.watchAndInvoke(() => bar, (e) { "
          "__e0.innerHTML = 'fo\${bar}o'; });"));
    });

    test('inserted for class', () {
      var elem = parseSubtree('<div class="{{bar}} {{foo}}" />');
      var emitter = new DataBindingEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace('''
          _stopWatcher__e0_1 = autogenerated.watchAndInvoke(() => bar, (e) {
          if (e.oldValue != null && e.oldValue != '') {
          __e0.classes.remove(e.oldValue);
          }
          if (e.newValue != null && e.newValue != '') {
          __e0.classes.add(e.newValue);
          }
          });
          _stopWatcher__e0_2 = autogenerated.watchAndInvoke(() => foo, (e) {
          if (e.oldValue != null && e.oldValue != '') {
          __e0.classes.remove(e.oldValue);
          }
          if (e.newValue != null && e.newValue != '') {
          __e0.classes.add(e.newValue);
          }
          });
          '''));
    });

    test('inserted for style map', () {
      var elem = parseSubtree('<div style-map="{{bar}}"></div>');
      var emitter = new DataBindingEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '''_stopWatcher__e0_1 = autogenerated.watchAndInvoke(() => bar, (e) {
            if (e.oldValue != null && e.oldValue is Map<String, Object>) {
              if (e.newValue is Map && e.oldValue.keys == e.newValue.keys) {
                // No need to clear the values as they will be set by the new values.
              } else {
                // Reset all css properties if any of the keys are different.
                e.oldValue.keys.forEach((property) => __e0.style.removeProperty(property));
              }
            }
            if (e.newValue != null && e.newValue is Map<String, String>) {            
              e.newValue.forEach((property, value) => __e0.style.setProperty(property, value));
            }
            });'''));
    });

    test('removed', () {
      var elem = parseSubtree('<div foo="{{bar}}"></div>');
      var emitter = new DataBindingEmitter(analyzeElement(elem));
      expect(_removed(emitter), equalsIgnoringWhitespace(
          '_stopWatcher__e0_1();'));
    });
  });

  group('emit main page class', () {
    test('external resource URLs', () {
      var html =
          '<html><head>'
          '<script src="http://example.com/a.js" type="text/javascript"></script>'
          '<script src="//example.com/a.js" type="text/javascript"></script>'
          '<script src="/a.js" type="text/javascript"></script>'
          '<link href="http://example.com/a.css" rel="stylesheet">'
          '<link href="//example.com/a.css" rel="stylesheet">'
          '<link href="/a.css" rel="stylesheet">'
          '</head><body></body></html>';
      var doc = parseDocument(html);
      var fileInfo = analyzeNodeForTesting(doc);
      fileInfo.userCode = new DartCodeInfo('main', null, [], '');
      var pathInfo = new PathInfo(new Path('a'), new Path('b'));

      var emitter = new MainPageEmitter(fileInfo);
      emitter.run(doc, pathInfo);
      expect(doc.outerHTML, equals(html));
    });
  });
}

_declarations(Emitter emitter) {
  var context = new Context();
  emitter.emitDeclarations(context);
  return context.declarations.toString().trim();
}

_created(Emitter emitter) {
  var context = new Context();
  emitter.emitDeclarations(context);
  emitter.emitCreated(context);
  return context.createdMethod.toString().trim();
}

_inserted(Emitter emitter) {
  var context = new Context();
  emitter.emitDeclarations(context);
  emitter.emitInserted(context);
  return context.insertedMethod.toString().trim();
}

_removed(Emitter emitter) {
  var context = new Context();
  emitter.emitDeclarations(context);
  emitter.emitRemoved(context);
  return context.removedMethod.toString().trim();
}

_createdRecursive(ElementInfo info) {
  var context = new Context();
  new RecursiveEmitter(null, context).visit(info);
  return context.createdMethod.toString().trim();
}

_declarationsRecursive(ElementInfo info) {
  var context = new Context();
  new RecursiveEmitter(null, context).visit(info);
  return context.declarations.toString().trim();
}
