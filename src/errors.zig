pub const success: u8 = 0;
pub const failure: u8 = 1;
pub const usage: u8 = 2;

pub const ValidationError = error{
    EmptyCommandName,
    EmptyAlias,
    DuplicateCommandName,
    DuplicateAlias,
    InvalidDefaultChild,
    EmptyOptionName,
    DuplicateOptionName,
    DuplicateShortOption,
    EmptyPositionalName,
    DuplicatePositionalName,
    RequiredPositionalAfterOptional,
    VariadicPositionalNotLast,
    CommandCycle,
    CommandTreeTooDeep,
};
