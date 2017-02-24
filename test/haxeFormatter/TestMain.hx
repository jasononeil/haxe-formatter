package haxeFormatter;

import haxe.Json;
import haxe.PosInfos;
import haxe.io.Path;
import haxe.unit.TestResult;
import haxe.unit.TestRunner.print;
import haxe.unit.TestStatus;
import haxeFormatter.Configuration;
import sys.FileSystem;
import sys.io.File;
using StringTools;

typedef TestConfiguration = {
    > Configuration,
    var testType:TestType;
}

@:enum abstract TestType(String) {
    /** simple test with config, source and expected outcome **/
    var Regular = "regular";
    /** expected block is omitted, as source == expected **/
    var Noop = "noop";
    /** a second test is generated, with a "flipped config" and source and expected swapped **/
    var Invertible = "invertible";

    public function toString() return this;
}

class TestMain {
    static function main() {
        new TestMain();
    }

    public function new() {
        var testResult = new TestResult();
        var dir = "test/haxeFormatter/cases";
        for (file in FileSystem.readDirectory(dir)) {
            if (!file.endsWith(".dump"))
                continue;
            for (result in processTestDefinition(dir, file))
                testResult.add(result);
        }

        Sys.println(testResult.toString() + "\n ");
        Sys.exit(if (testResult.success) 0 else 1);
    }

    public function processTestDefinition(dir:String, file:String):Array<TestStatus> {
        var absPath = Path.join([Sys.getCwd(), dir, file]);
        var content = File.getContent(absPath);
        var nl = "(\r?\n)";
        var reg = new EReg('$nl$nl---$nl$nl', "g");
        var segments = reg.split(content);
        var config:TestConfiguration = try Json.parse(segments[0]) catch(e:Any) {
            throw 'Could not parse config: ${segments[0]}\nReason: $e';
            null;
        }

        var isNoopTest = config.testType == Noop;
        var requiredSegments = if (isNoopTest) 2 else 3;
        if (segments.length != requiredSegments)
            throw 'Exactly $requiredSegments segments expected, but found ${segments.length}.';

        var name = Path.withoutExtension(file);
        var source = segments[1];
        var expected = if (isNoopTest) source else segments[2];

        print('Test: $name ');

        var results = [];
        results.push(runTest(name, config, source, expected));

        // run a second, inverted test?
        if (config.testType == Invertible)
            results.push(runTest("Inverted_" + name, invertConfig(config), expected, source));

        Sys.println("");
        return results;
    }

    function runTest(name:String, config:TestConfiguration, sourceCode:String, formattedCode:String, ?c:PosInfos):TestStatus {
        var status = new TestStatus();
        status.done = true;
        status.classname = name;
        status.method = config.testType.toString();

        switch (Formatter.formatSource(sourceCode, File, config)) {
            case Success(result):
                if (result != formattedCode) {
                    status.error = 'Test case "$name" failed. Expected:\n\n$formattedCode \n\nbut was:\n\n$result';
                    status.success = false;
                    print("E");
                } else {
                    status.success = true;
                    print(".");
                }
            case Failure(reason):
                status.error = 'Formatting failed with $reason';
                status.success = false;
                print("W");
        }

        return status;
    }

    function invertConfig(config:TestConfiguration):TestConfiguration {
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
}