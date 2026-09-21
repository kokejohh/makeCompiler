pub const ParseError = error{
    CodeLengthIsZero,
    UnterminatedString,
    UnexpectedValue,
    UnterminatedChar,
};
