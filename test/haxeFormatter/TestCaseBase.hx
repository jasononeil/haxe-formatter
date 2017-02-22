package haxeFormatter;

import haxe.PosInfos;
import haxe.unit.TestCase;
import haxeFormatter.Configuration;
import haxeFormatter.Formatter;

class TestCaseBase extends TestCase {
    function assertFormat(formattedCode:String, sourceCode:String, config:Configuration, ?c:PosInfos) {
        switch (Formatter.format(sourceCode, config)) {
            case Success(data): assertEquals(formattedCode, data, c);
            case Failure(_): assertFalse(true, c);
        }
    }
}