package haxeFormatter;

import haxe.Json;
import haxe.PosInfos;
import haxe.io.Path;
import haxe.unit.TestCase;
import haxe.unit.TestRunner;
import haxeFormatter.Configuration;
import sys.FileSystem;
import sys.io.File;
using StringTools;

class TestMain {
    public function new() {
        var runner = new TestRunner();
        runner.add(new FormattingTestCase());
        var success = runner.run();
        Sys.exit(if (success) 0 else 1);
    }

    static function main() {
        new TestMain();
    }
}

class FormattingTestCase extends TestCase {
    function testAll() {
        var dir = "test/haxeFormatter/cases";
        for (file in FileSystem.readDirectory(dir)) {
            if (!file.endsWith(".dump"))
                continue;

            var absPath = Path.join([Sys.getCwd(), dir, file]);
            var content = File.getContent(absPath);
            var nl = "(\r?\n)";
            var reg = new EReg('$nl$nl---$nl$nl', "g");
            var segments = reg.split(content);
            if (segments.length != 3)
                fail("Three segments needed: config, source and expected");

            var config:Configuration = try Json.parse(segments[0]) catch(e:Any) {
                fail('Could not parse config: ${segments[0]}\nReason: $e');
                null;
            }
            assertFormat(file, config, segments[1], segments[2]);
        }
    }

    function fail(msg:String, ?c:PosInfos):Void {
        currentTest.done = true;
        currentTest.success = false;
        currentTest.error = msg;
        currentTest.posInfos = c;
        throw currentTest;
    }

    function assertFormat(file:String, config:Configuration, sourceCode:String, formattedCode:String, ?c:PosInfos) {
        switch (Formatter.format(sourceCode, config)) {
            case Success(result):
                if (result != formattedCode)
                   fail('Test case "$file" failed. Expected:\n\n$formattedCode \n\nbut was:\n\n$result');
            case Failure(reason):
                fail('Formatting failed with $reason');
        }
        assertTrue(true);
    }
}