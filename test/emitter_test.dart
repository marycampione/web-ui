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

      test('1 way binding in content with no id', () {
        var elem = parseSubtree('<div>{{bar}}</div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_declarations(emitter), 'autogenerated.DivElement __e1;');
      });

      test('1 way binding in content with id', () {
        var elem = parseSubtree('<div id="my-id">{{bar}}</div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem));
        expect(_declarations(emitter), 'autogenerated.DivElement _myId;');
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

      test('sibling of a data-bound text node, with id and children', () {
        var elem = parseSubtree('<div id="a1">{{x}}<div id="a2">a</div></div>');
        var emitter = new ElementFieldEmitter(analyzeElement(elem).children[1]);
        expect(_created(emitter),
            "_a2 = new autogenerated.Element.html('<div id=\"a2\">a</div>');");
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

  group('emit text node field', () {
    test('declaration', () {
      var elem = parseSubtree('<div>{{bar}}</div>');
      var emitter = new ContentFieldEmitter(analyzeElement(elem).children[0]);
      expect(_declarations(emitter), 'var _binding0;');
    });

    test('created', () {
      var elem = parseSubtree('<div>{{bar}}</div>');
      var emitter = new ContentFieldEmitter(analyzeElement(elem).children[0]);
      expect(_created(emitter),
        '_binding0 = autogenerated.nodeForBinding(bar);');
    });

    test('inserted', () {
      var elem = parseSubtree('<div>{{bar}}</div>');
      var emitter = new ContentFieldEmitter(analyzeElement(elem).children[0]);
      expect(_inserted(emitter), '');
    });

    test('removed', () {
      var elem = parseSubtree('<div>{{bar}}</div>');
      var emitter = new ContentFieldEmitter(analyzeElement(elem).children[0]);
      expect(_removed(emitter), '_binding0 = null;');
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
          '_listener__e0_foo_1 = '
          '  (__e) { bar(__e); autogenerated.dispatch(); }; '
          '__e0.on.foo.add(_listener__e0_foo_1);'));
    });

    test('inserted for input value data bind', () {
      var elem = parseSubtree('<input data-bind="value:bar"></input>');
      var emitter = new EventListenerEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '_listener__e0_input_1 = (__e) { bar = __e0.value; '
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

  group('emit data binding watchers for attributes', () {
    test('declaration', () {
      var elem = parseSubtree('<div foo="{{bar}}"></div>');
      var emitter = new AttributeEmitter(analyzeElement(elem));
      expect(_declarations(emitter),
        equals('List<autogenerated.WatcherDisposer> _stoppers1;'));
    });

    test('created', () {
      var elem = parseSubtree('<div foo="{{bar}}"></div>');
      var emitter = new AttributeEmitter(analyzeElement(elem));
      expect(_created(emitter), equals('_stoppers1 = [];'));
    });

    test('inserted', () {
      var elem = parseSubtree('<div foo="{{bar}}"></div>');
      var emitter = new AttributeEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '_stoppers1.add(autogenerated.watchAndInvoke(() => '
          'bar, (__e) { __e0.attributes["foo"] = __e.newValue; }));'));
    });

    test('inserted for 1-way binding with dom accessor', () {
      var elem = parseSubtree('<input value="{{bar}}">');
      var emitter = new AttributeEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '_stoppers1.add(autogenerated.watchAndInvoke(() => bar, (__e) { '
          '__e0.value = __e.newValue; }));'));
    });

    test('inserted for 2-way binding with dom accessor', () {
      var elem = parseSubtree('<input data-bind="value:bar">');
      var emitter = new AttributeEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '_stoppers1.add(autogenerated.watchAndInvoke(() => bar, (__e) { '
          '__e0.value = __e.newValue; }));'));
    });

    test('inserted for data attribute', () {
      var elem = parseSubtree('<div data-foo="{{bar}}"></div>');
      var emitter = new AttributeEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace(
          '_stoppers1.add(autogenerated.watchAndInvoke(() => bar, (__e) { '
          '__e0.attributes["data-foo"] = __e.newValue; }));'));
    });

    test('inserted for class', () {
      var elem = parseSubtree('<div class="{{bar}} {{foo}}" />');
      var emitter = new AttributeEmitter(analyzeElement(elem));
      expect(_inserted(emitter), equalsIgnoringWhitespace('''
          _stoppers1.add(autogenerated.bindCssClasses(__e0, () => bar));
          _stoppers1.add(autogenerated.bindCssClasses(__e0, () => foo));
          '''));
    });

    test('inserted for style', () {
      var elem = parseSubtree('<div data-style="bar"></div>');
      var emitter = new AttributeEmitter(analyzeElement(elem));
      expect(_inserted(emitter),
          '_stoppers1.add(autogenerated.bindStyle(__e0, () => bar));');
    });

    test('removed', () {
      var elem = parseSubtree('<div foo="{{bar}}"></div>');
      var emitter = new AttributeEmitter(analyzeElement(elem));
      expect(_removed(emitter), equalsIgnoringWhitespace(
          '(_stoppers1..forEach((s) => s())).clear();'));
    });
  });

  group('emit data binding watchers for content', () {
    test('declaration', () {
      var elem = parseSubtree('<div>fo{{bar}}o</div>');
      var emitter = new ContentDataBindingEmitter(
          analyzeElement(elem).children[1]);
      expect(_declarations(emitter),
        equals('List<autogenerated.WatcherDisposer> _stoppers1;'));
    });

    test('inserted', () {
      var elem = parseSubtree('<div>fo{{bar}}o</div>');
      var emitter = new ContentDataBindingEmitter(
          analyzeElement(elem).children[1]);
      expect(_inserted(emitter), equalsIgnoringWhitespace(r'''
          _stoppers1.add(autogenerated.watchAndInvoke(() => bar, (__e) {
            _binding0 = autogenerated.updateBinding(__e.newValue, _binding0);
          }));'''));
    });

    test('removed', () {
      var elem = parseSubtree('<div>fo{{bar}}o</div>');
      var emitter = new ContentDataBindingEmitter(
          analyzeElement(elem).children[1]);
      expect(_removed(emitter), equalsIgnoringWhitespace(
          '(_stoppers1..forEach((s) => s())).clear();'));
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
