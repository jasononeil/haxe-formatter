package haxeFormatter.cases;

class SortImportsTest extends TestCaseBase {
    var source = '
package;

using StringTools;
import hxParser.JsonParser;
import util.Result;
import hxParser.HxParser;

class C {
    function new() {}
}';

    function testBasicSort() {
        var formatted = '
package;

import hxParser.HxParser;
import hxParser.JsonParser;
import util.Result;
using StringTools;

class C {
    function new() {}
}';
        assertFormat(formatted, source, { imports: { sort: true }});
    }

    function testNoSort() {
        assertFormat(source, source, { imports: { sort: false }});
    }
}