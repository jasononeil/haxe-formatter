package util;

class StringTools {
    public static inline function has(s:String, substring:String):Bool {
        return s != null && s.indexOf(substring) != -1;
    }

    public static inline function isWhitespace(s:String) {
        return ~/\s+/.match(s);
    }

    public static inline function isNewline(s:String) {
        return s == "\n" || s == "\r" || s == "\r\n";
    }
}