function blkStruct = slblocks
% This function specifies that the library 'mylib'
% should appear in the Library Browser with the 
% name 'My Library'

    Browser.Library = 'VACLib';
    % 'mylib' is the name of the library

    Browser.Name = 'Volvo Architechture Components';
    % 'My Library' is the library name that appears
    % in the Library Browser
    Browser(1).IsFlat  = 0;
  

    blkStruct.Browser = Browser;
