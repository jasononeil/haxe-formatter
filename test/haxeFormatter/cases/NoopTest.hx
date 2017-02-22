package haxeFormatter.cases;

class NoopTest extends TestCaseBase {
    function testNoop() {
        var source = '
class Test {
    static function main() {
        trace("Haxe is great!");
    }
}';
        assertFormat(source, source, {});
    }
}