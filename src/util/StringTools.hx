package util;

class StringTools {
    public static inline function has(s:String, substring:String):Bool {
        return s != null && s.indexOf(substring) != -1;
    }

    public static inline function isWhitespace(s:String) {
        return ~/^\s+$/.match(s);
    }

    public static inline function isNewline(s:String) {
        return s == "\n" || s == "\r" || s == "\r\n";
    }

    public static inline function isTabOrSpace(s:String) {
        return ~/^[ \t]+$/.match(s);
    }

    public static inline function times(s:String, amount:Int) {
        return [for (i in 0...amount) s].join("");
    }
}