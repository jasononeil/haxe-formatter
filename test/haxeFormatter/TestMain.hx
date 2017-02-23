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

typedef TestConfiguration = {
    > Configuration,
    var testConfig:TestFlags;
}

typedef TestFlags = {
    /** expected block is omitted, as source == expected **/
    @:optional var noop:Bool;
    /** a second test is generated, with a "flipped config" and source and expected swapped **/
    @:optional var invertible:Bool;
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
            var config:TestConfiguration = try Json.parse(segments[0]) catch(e:Any) {
                fail('Could not parse config: ${segments[0]}\nReason: $e');
                null;
            }
            if (config.testConfig == null)
                config.testConfig = {};
            var isNoopTest = config.testConfig.noop == true;
            var requiredSegments = if (isNoopTest) 2 else 3;
            if (segments.length != requiredSegments)
                fail('Exactly $requiredSegments segments expected, but found ${segments.length}.');

            var name = Path.withoutExtension(file);
            var source = segments[1];
            var expected = if (isNoopTest) source else segments[2];
            assertFormat(name, config, source, expected);

            var isInvertible = config.testConfig.invertible == true;
            if (isInvertible) {
                // run a second, inverted test
                assertFormat("Inverted_" + name, invertConfig(config), expected, source);
            }
        }
    }

    function invertConfig(config:Configuration):Configuration {
        config = Reflect.copy(config);
        // there has to be a smarter way
        if (config.imports != null && config.imports.sort != null) {
            config.imports.sort = !config.imports.sort;
        }
        function flipWhitespacePolicy(policy) return switch (policy) {
            case null, Keep: Keep;
            case Add: Remove;
            case Remove: Add;
        }

        if (config.padding != null && config.padding.typeHintColon != null) {
            var colon = config.padding.typeHintColon;
            colon.before = flipWhitespacePolicy(colon.before);
            colon.after = flipWhitespacePolicy(colon.after);
        }
        return config;
    }

    function fail(msg:String, ?c:PosInfos):Void {
        currentTest.done = true;
        currentTest.success = false;
        currentTest.error = msg;
        currentTest.posInfos = c;
        throw currentTest;
    }

    function assertFormat(name:String, config:Configuration, sourceCode:String, formattedCode:String, ?c:PosInfos) {
        switch (Formatter.formatSource(sourceCode, config)) {
            case Success(result):
                if (result != formattedCode)
                   fail('Test case "$name" failed. Expected:\n\n$formattedCode \n\nbut was:\n\n$result');
            case Failure(reason):
                fail('Formatting failed with $reason');
        }
        assertTrue(true);
    }
}