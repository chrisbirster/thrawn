pub const success: u8 = 0;
pub const failure: u8 = 1;
pub const usage: u8 = 2;

pub const ValidationError = error{
    EmptyCommandName,
    DuplicateCommandName,
    DuplicateAlias,
    InvalidDefaultChild,
    EmptyOptionName,
    DuplicateOptionName,
    DuplicateShortOption,
};
