package util;

class StringTools {
    public static function has(s:String, substring:String):Bool {
        return s != null && s.indexOf(substring) != -1;
    }

    public static function isWhitespace(s:String) {
        return ~/\s+/.match(s);
    }
}