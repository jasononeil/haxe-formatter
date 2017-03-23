package haxeFormatter;

import haxe.PosInfos;
import haxe.io.Path;
import haxe.unit.TestResult;
import haxe.unit.TestRunner.print;
import haxe.unit.TestStatus;
import haxeFormatter.Config;
import hxParser.HxParser.EntryPoint;
import sys.FileSystem;
import json2object.JsonParser;
import sys.io.File;
using StringTools;
using json2object.ErrorUtils;

typedef TestConfig = {
    > Config,
    @:optional var testProperties:TestProperties;
}

typedef TestProperties = {
    @:optional var type:TestType;
    @:optional var entryPoint:EntryPoint;
}

@:enum abstract TestType(String) to String {
    /** simple test with config, source and expected outcome **/
    var Regular = "regular";
    /** expected block is omitted, as source == expected **/
    var Noop = "noop";
    /** a second test is generated, with a "flipped config" and source and expected swapped **/
    var Invertible = "invertible";
}

class TestMain {
    static function main() {
        new TestMain();
    }

    public function new() {
        var singleDir = "test/haxeFormatter/single";
        var testResult = processTestDirectory(
            if (FileSystem.exists(singleDir) && FileSystem.readDirectory(singleDir).length > 0)
                singleDir
            else
                "test/haxeFormatter/cases");

        Sys.println(testResult.toString());
        if (testResult.success) updateResultFile("---");
        Sys.exit(if (testResult.success) 0 else 1);
    }

    function processTestDirectory(dir:String):TestResult {
        var testResult = new TestResult();
        for (file in FileSystem.readDirectory(dir)) {
            if (!file.endsWith(".hxtest"))
                continue;
            for (result in processTestDefinition(dir, file))
                testResult.add(result);
        }
        return testResult;
    }

    function processTestDefinition(dir:String, file:String):Array<TestStatus> {
        var path = Path.join([dir, file]);
        var content = sys.io.File.getContent(path);
        var nl = "(\r?\n)";
        var reg = new EReg('$nl$nl---$nl$nl', "g");
        var segments = reg.split(content);

        var parser = new JsonParser<TestConfig>();
        var config = parser.fromJson(segments[0], path);
        if (parser.warnings.length > 0) {
            Sys.println(parser.warnings.convertErrorArray());
            Sys.exit(1);
        }

        if (config.baseConfig == null)
            config.baseConfig = Noop;
        if (config.testProperties == null)
            config.testProperties = {};

        var isNoopTest = config.testProperties.type == Noop;
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
        if (config.testProperties.type == Invertible)
            results.push(runTest("Inverted_" + name, invertConfig(config), expected, source));

        Sys.println("");
        return results;
    }

    function runTest(name:String, config:TestConfig, sourceCode:String, formattedCode:String, ?c:PosInfos):TestStatus {
        var status = new TestStatus();
        status.done = true;
        status.classname = name;
        status.method = config.testProperties.type;

        switch (Formatter.formatSource(sourceCode, config.testProperties.entryPoint, config)) {
            case Success(result):
                if (result != formattedCode) {
                    status.error = 'Test case "$name" failed. Expected:\n\n$formattedCode\n\nbut was:\n\n$result';
                    status.success = false;
                    updateResultFile('$formattedCode---$result');
                    print("E");
                } else {
                    status.success = true;
                    print(".");
                }
            case Failure(reason):
                status.error = 'Formatting failed with \'$reason\'';
                status.success = false;
                print("W");
        }

        return status;
    }

    function updateResultFile(content:String) {
        sys.io.File.saveContent("test/formatter-result.txt", content);
    }

    function invertConfig(config:TestConfig):TestConfig {
        config = Reflect.copy(config);
        // there has to be a smarter way
        if (config.imports != null && config.imports.sort != null) {
            config.imports.sort = !config.imports.sort;
        }
        function invertTwoSidedPadding(padding):TwoSidedPadding return switch (padding) {
            case Ignore: Ignore;
            case Before: After;
            case After: Before;
            case None: Both;
            case Both: None;
        }
        function invertOneSidedPadding(padding):OneSidedPadding return switch (padding) {
            case OneSidedPadding.Ignore: Ignore;
            case Insert: Remove;
            case Remove: Insert;
        }
        function invertOptionalBool(bool):OptionalBool return switch (bool) {
            case Yes: No;
            case No: Yes;
            case Ignore: Ignore;
        }

        var padding = config.padding;
        if (padding != null) {
            padding.typeHintColon = invertTwoSidedPadding(config.padding.typeHintColon);
            padding.functionTypeArrow = invertTwoSidedPadding(config.padding.functionTypeArrow);
            padding.unaryOperator = invertOneSidedPadding(config.padding.unaryOperator);
            var binaryOperator = padding.binaryOperator;
            if (binaryOperator != null) {
                binaryOperator.defaultPadding = invertTwoSidedPadding(binaryOperator.defaultPadding);
                var padded = binaryOperator.padded;
                var unpadded = binaryOperator.unpadded;
                binaryOperator.padded = unpadded;
                binaryOperator.unpadded = padded;
            }
            padding.parenInner = invertOneSidedPadding(padding.parenInner);
            padding.beforeParenAfterKeyword = invertOneSidedPadding(padding.beforeParenAfterKeyword);
            var comma = padding.comma;
            if (comma != null) {
                comma.defaultPadding = invertTwoSidedPadding(comma.defaultPadding);
                comma.propertyAccess = invertTwoSidedPadding(comma.propertyAccess);
            }
        }
        var brackets = config.brackets;
        if (brackets != null) {
            var newlineBeforeOpening = brackets.newlineBeforeOpening;
            if (newlineBeforeOpening != null) {
                newlineBeforeOpening.type = invertOptionalBool(newlineBeforeOpening.type);
                newlineBeforeOpening.field = invertOptionalBool(newlineBeforeOpening.field);
                newlineBeforeOpening.block = invertOptionalBool(newlineBeforeOpening.block);
            }
            brackets.newlineBeforeElse = invertOptionalBool(brackets.newlineBeforeElse);
        }
        return config;
    }
}