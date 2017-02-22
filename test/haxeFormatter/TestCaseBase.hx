package haxeFormatter;

import haxe.PosInfos;
import haxe.unit.TestCase;
import haxeFormatter.Configuration;
import haxeFormatter.HaxeFormatter;

class TestCaseBase extends TestCase {
    function assertFormat(formattedCode:String, sourceCode:String, config:Configuration, ?c:PosInfos) {
        var formatter = new HaxeFormatter(config);
        switch (formatter.format(sourceCode)) {
            case Success(data): assertEquals(formattedCode, data, c);
            case Failure(_): assertFalse(true, c);
        }
    }
}