package haxeFormatter;

import haxe.unit.TestCase;
import haxe.unit.TestRunner;

class TestMain {
    public function new() {
        var runner = new TestRunner();

        CompileTime.importPackage("haxeFormatter.cases");

        var tests = CompileTime.getAllClasses(TestCase);
        for (testClass in tests) runner.add(Type.createInstance(testClass, []));

        var success = runner.run();
        Sys.exit(if (success) 0 else 1);
    }

    static function main() {
        new TestMain();
    }
}