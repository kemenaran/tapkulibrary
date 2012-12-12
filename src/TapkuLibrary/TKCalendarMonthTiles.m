//
//  TKCalendarMonthTiles
//
//  Created by Sean Freitag on 9/20/12.
//  Copyright 2012 Banno, LLC. All rights reserved.
//


#import "TapkuLibrary.h"
#import "TKCalendarMonthTiles.h"

@interface TKCalendarMonthTilesTile : NSObject

@property (nonatomic) NSUInteger row;
@property (nonatomic) NSUInteger column;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic) BOOL selectable;

@end

@implementation TKCalendarMonthTilesTile
@end

@interface TKCalendarMonthTiles ()

@property (nonatomic) BOOL startsOnSunday;
@property (nonatomic) int today;
@property (nonatomic) int firstWeekday;
@property (nonatomic) int daysInMonth;

@property (nonatomic, strong) TKCalendarMonthTilesTile *selectedTile;
@property (nonatomic, strong, readonly) UILabel *currentDay;

@property (nonatomic, strong) NSArray *tiles;
@property (nonatomic, strong) NSArray *accessibleElements;

@end

@implementation TKCalendarMonthTiles {
    UILabel *_currentDay;
}

#define dotFontSize 18.0
#define dateFontSize 22.0

#define TODAY_TILE          TKBUNDLE(@"TapkuLibrary.bundle/Images/calendar/Month Calendar Today Tile.png")
#define TODAY_SELECTED_TILE TKBUNDLE(@"TapkuLibrary.bundle/Images/calendar/Month Calendar Today Selected Tile.png")
#define DATE_TILE           TKBUNDLE(@"TapkuLibrary.bundle/Images/calendar/Month Calendar Date Tile.png")
#define DATE_GRAY_TILE      TKBUNDLE(@"TapkuLibrary.bundle/Images/calendar/Month Calendar Date Tile Gray.png")
#define DATE_SELECTED_TILE  TKBUNDLE(@"TapkuLibrary.bundle/Images/calendar/Month Calendar Date Tile Selected.png")

- (NSArray *)tilesForMonth:(NSDate *)month startsOnSunday:(BOOL)sunday {
    NSCalendar *calendar = [NSCalendar currentCalendar];

    NSInteger weekday = [calendar components:NSWeekdayCalendarUnit fromDate:month].weekday;
    NSUInteger daysInMonth = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:month].length;

    NSInteger offset = weekday - (sunday ? 1 : 2);
    if (offset < 0) offset = 7 + offset;

    NSUInteger daysInMonthWithOffset = daysInMonth + offset;

    NSUInteger rows = (daysInMonthWithOffset / 7) + (daysInMonthWithOffset % 7 == 0 ? 0 : 1);

    NSMutableArray *array = [NSMutableArray array];

    for (NSUInteger row = 0; row < rows; row++) {
        for (NSUInteger col = 0; col < 7; col++) {
            TKCalendarMonthTilesTile *tile = [[TKCalendarMonthTilesTile alloc] init];
            tile.row = row;
            tile.column = col;
            NSDate *date = [month dateByAddingDays:(row * 7) + col - offset];
            tile.date = date;

            [array addObject:tile];
        }
    }

    return array;
}

- (id)initWithMonth:(NSDate *)date startDayOnSunday:(BOOL)sunday {
	if(!(self=[super initWithFrame:CGRectZero])) return nil;

	self.monthDate = date;
    self.startsOnSunday = sunday;

	TKDateInformation dateInfo = [self.monthDate dateInformation];
    self.firstWeekday = dateInfo.weekday;

    self.tiles = [self tilesForMonth:date startsOnSunday:sunday];

    self.daysInMonth = [[self.monthDate nextMonth] daysBetweenDate:self.monthDate];

	CGFloat h = 44.0f * [date rowsOnCalendarStartingOnSunday:sunday];

	TKDateInformation todayInfo = [[NSDate date] dateInformation];
    self.today = dateInfo.month == todayInfo.month && dateInfo.year == todayInfo.year ? todayInfo.day : -5;

	self.frame = CGRectMake(0, 1.0, 320.0f, h+1);

	self.multipleTouchEnabled = NO;

	return self;
}

- (void)setDelegate:(id <TKCalendarMonthTilesDelegate>)delegate {
    _delegate = delegate;

    for (TKCalendarMonthTilesTile *tile in self.tiles)
        tile.selectable = [self.delegate calendarMonthTiles:self canSelectDate:tile.date];
    
    // The accessible elements depends on the selected tiles: clear the cache so they can be
    // regenerated with the updated selectable values
    _accessibleElements = nil;
}

- (CGRect) rectForTile:(TKCalendarMonthTilesTile*)tile
{
    return CGRectMake(tile.column * 46, tile.row * 44, 46, 44);
}

- (void)drawTileInRect:(CGRect)rect day:(int)day font:(UIFont *)font color:(UIColor *)color {
	NSString *str = [NSString stringWithFormat:@"%d",day];

    [color set];

	rect.size.height -= 2;
	[str drawInRect:rect
		   withFont:font
	  lineBreakMode: NSLineBreakByWordWrapping
		  alignment: NSTextAlignmentCenter];
}

- (void) drawRect:(CGRect)rect {

	CGContextRef context = UIGraphicsGetCurrentContext();
	UIImage *tile = [UIImage imageWithContentsOfFile:DATE_TILE];
	CGRect r = CGRectMake(0, 0, 46, 44);
	CGContextDrawTiledImage(context, r, tile.CGImage);

    UIFont *font = [UIFont boldSystemFontOfSize:dateFontSize];
    NSCalendar *calendar = [NSCalendar currentCalendar];

    for (TKCalendarMonthTilesTile *dayTile in self.tiles) {
        NSInteger day = [calendar components:NSDayCalendarUnit fromDate:dayTile.date].day;
        CGRect tileRect = [self rectForTile:dayTile];
        CGRect dayRect = CGRectMake(tileRect.origin.x, tileRect.origin.y + 6,
                                    tileRect.size.width + 1, tileRect.size.height +1);

        UIColor *color = ([[dayTile.date monthDate] isEqualToDate:self.monthDate]
                          ? [UIColor colorWithRed:0.224 green:0.278 blue:0.337 alpha:1.000]
                          : [UIColor grayColor]);

        if (!dayTile.selectable && [self.monthDate isEqualToDate:[dayTile.date monthDate]])
            color = [UIColor colorWithRed:0.438 green:0.492 blue:0.550 alpha:1.000];

        if (self.today == day && [[dayTile.date monthDate] isEqualToDate:self.monthDate]) {
            CGRect todayTileRect = dayRect;
            todayTileRect.origin.y -= 7;
            [[UIImage imageWithContentsOfFile:TODAY_TILE] drawInRect:todayTileRect];
            color = [UIColor whiteColor];
        }

        [self drawTileInRect:dayRect day:day font:font color:color];
    }
}

- (void)selectDate:(NSDate *)date {
    TKCalendarMonthTilesTile *tile = nil;

    for (TKCalendarMonthTilesTile *dayTile in self.tiles) {
        if ([dayTile.date isSameDay:date]) {
            tile = dayTile;
            break;
        }
    }

    if (tile == nil) return;
    
    self.selectedTile = tile;

    if ([date isSameDay:[NSDate date]])
		self.selectedImageView.image = [UIImage imageWithContentsOfFile:TODAY_SELECTED_TILE];
	else
        self.selectedImageView.image = [[UIImage imageWithContentsOfFile:DATE_SELECTED_TILE] stretchableImageWithLeftCapWidth:1 topCapHeight:0];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    self.currentDay.text = [NSString stringWithFormat:@"%d", [calendar components:NSDayCalendarUnit fromDate:date].day];

	CGRect r = self.selectedImageView.frame;
	r.origin.x =  (float)(tile.column * 46);
	r.origin.y = ((float)(tile.row    * 44)) - 1;
	self.selectedImageView.frame = r;
}

- (NSDate *)dateSelected {
	return self.selectedTile.date;
}

- (TKCalendarMonthTilesTile *)tileAtPoint:(CGPoint)point {
    int column = (int) (point.x / 46);
    int row    = (int) (point.y / 44);

    for (TKCalendarMonthTilesTile *tile in self.tiles)
        if (tile.selectable && tile.column == column && tile.row == row)
            return tile;

    return nil;
}

- (void)reactToTouch:(UITouch *)touch {
	CGPoint p = [touch locationInView:self];
	if(p.y > self.bounds.size.height || p.y < 0) return;

    TKCalendarMonthTilesTile *tile = [self tileAtPoint:p];
    if (self.selectedTile == tile || tile == nil) return;
    self.selectedTile = tile;

	int column = tile.column;
    int row = tile.row;
    int day = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:tile.date].day;

	if(![[tile.date monthDate] isEqualToDate:self.monthDate]) {
		self.selectedImageView.image = [UIImage imageWithContentsOfFile:DATE_GRAY_TILE];
	} else if(day == self.today){
		self.selectedImageView.image = [UIImage imageWithContentsOfFile:TODAY_SELECTED_TILE];
	} else {
		NSString *path = DATE_SELECTED_TILE;
		self.selectedImageView.image = [[UIImage imageWithContentsOfFile:path] stretchableImageWithLeftCapWidth:1 topCapHeight:0];
	}

	self.currentDay.text = [NSString stringWithFormat:@"%d",day];

	CGRect r = self.selectedImageView.frame;
	r.origin.x = (column * 46);
	r.origin.y = (row * 44)-1;
	self.selectedImageView.frame = r;

    [self.delegate dateWasSelected:tile.date];
}

#pragma mark UIResponder touch events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self reactToTouch:[touches anyObject]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self reactToTouch:[touches anyObject]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self reactToTouch:[touches anyObject]];
}

#pragma mark Properties

- (UILabel *) currentDay{
	if(_currentDay ==nil){
		CGRect r = self.selectedImageView.bounds;
		r.origin.y -= 2;
		_currentDay = [[UILabel alloc] initWithFrame:r];
		_currentDay.text = @"1";
		_currentDay.textColor = [UIColor whiteColor];
		_currentDay.backgroundColor = [UIColor clearColor];
		_currentDay.font = [UIFont boldSystemFontOfSize:dateFontSize];
		_currentDay.textAlignment = NSTextAlignmentCenter;
		_currentDay.shadowColor = [UIColor darkGrayColor];
		_currentDay.shadowOffset = CGSizeMake(0, -1);
	}
	return _currentDay;
}

- (UIImageView *) selectedImageView{
	if(_selectedImageView ==nil){

		NSString *path = DATE_SELECTED_TILE;
		UIImage *img = [[UIImage imageWithContentsOfFile:path] stretchableImageWithLeftCapWidth:1 topCapHeight:0];
		_selectedImageView = [[UIImageView alloc] initWithImage:img];
		_selectedImageView.frame = CGRectMake(0, 0, 47, 45);
        [self.selectedImageView addSubview:self.currentDay];
        [self addSubview:_selectedImageView];
	}
	return _selectedImageView;
}

- (void) setSelectedTile:(TKCalendarMonthTilesTile *)selectedTile {
    _selectedTile = selectedTile;
    
    // The accessibilityFrame depends on the selected tile: clear the accessibility cache on selected tile change
    _accessibleElements = nil;
}

#pragma mark Accessibility

- (void) didMoveToWindow
{
    // The accessibilityFrame depends on the window coordinates: clear the accessibility cache on window change
    _accessibleElements = nil;
}

- (UIAccessibilityElement *)accessibilityElementForTile:(TKCalendarMonthTilesTile *)tile {
    if (!tile.selectable)
        return nil;
    
    static NSDateFormatter *localizedDateFormatter;
    static NSDateFormatter *machineReadableDateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localizedDateFormatter = [[NSDateFormatter alloc] init];
        localizedDateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"EEEEdMMMM" options:0 locale:[NSLocale currentLocale]];
        
        machineReadableDateFormatter = [[NSDateFormatter alloc] init];
        machineReadableDateFormatter.dateFormat = @"yyyy-MM-dd";
    });
    
    UIAccessibilityElement *accessibleTile = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
    
    accessibleTile.isAccessibilityElement = YES;
    accessibleTile.accessibilityFrame = [self convertRect:[self rectForTile:tile] toView:nil];
    accessibleTile.accessibilityLabel = [localizedDateFormatter stringFromDate:tile.date];
    accessibleTile.accessibilityIdentifier = [machineReadableDateFormatter stringFromDate:tile.date];
    accessibleTile.accessibilityTraits = UIAccessibilityTraitButton;
    if ([tile isEqual:self.selectedTile])
        accessibleTile.accessibilityTraits |= UIAccessibilityTraitSelected;
    
    return accessibleTile;
}

- (NSArray *)accessibleElements {
    if ( _accessibleElements == nil ) {
        
        NSMutableArray *accessibleElements = [NSMutableArray arrayWithCapacity:[self.tiles count]];
        for (TKCalendarMonthTilesTile *tile in self.tiles) {
            UIAccessibilityElement *accessibleTile = [self accessibilityElementForTile:tile];
            if (accessibleTile)
                [accessibleElements addObject:accessibleTile];
        }
        
        _accessibleElements = accessibleElements;
    }
    
    return _accessibleElements;
}

- (BOOL)isAccessibilityElement {
    // The container itself is not accessible; it merely returns accessibility elements for its items
    return NO;
}

- (NSInteger)accessibilityElementCount {
    return [[self accessibleElements] count];
}

- (id)accessibilityElementAtIndex:(NSInteger)index {
    return [[self accessibleElements] objectAtIndex:index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
    return [[self accessibleElements] indexOfObject:element];
}

@end