pub const ParseError = error{
    CodeLengthIsZero,
    UnterminatedString,
    UnexpectedValue,
    UnterminatedChar,
};

pub const ASTError = error{
    InfiniteWhileLoop,
    IndexOutOfRange,
    InvalidDeclaration,
    UnexpectedType,
    UnimplementedType,
    MissingExpectedType,
    UnexpectedEndOfFile,
    NullType,
    OutOfMemory,
};
