//
//  ViewController.m
//  BLEEncrpytionDataTransfer
//


#import "ViewController.h"
#import "WMLShortRangeManager.h"
#import "ZQQSecurity.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, WMLShortRangeManagerDelegate> {
    WMLShortRangeManager *bluetoothManager;
    NSMutableArray *receivedDataArr;
    
    ZQQSecurity *secuity;
}
@property (weak, nonatomic) IBOutlet UITextField *inputLabel;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;
@property (weak, nonatomic) IBOutlet UITableView *receivedTable;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self initBLE];
    receivedDataArr = [[NSMutableArray alloc] init];
    secuity = [[ZQQSecurity alloc] initWithKey:[ZQQSecurity getSecurityKey]];
}

- (void)initBLE {
    bluetoothManager = [[WMLShortRangeManager alloc] init];
    bluetoothManager.delegate = self;
    [bluetoothManager scan];
}

- (IBAction)sendBtnClicked:(id)sender {
    NSString *sendStr = @"NA Value";
    if (![_inputLabel.text  isEqualToString:@""]) {
        sendStr = _inputLabel.text;
    }
    [bluetoothManager sendMessage:[secuity aes256EncryptWithString:sendStr]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 
#pragma mark - WMLShortRangeManager
- (void)shortRangeManager:(WMLShortRangeManager *)shortRangeManager didReceiveData:(NSString *)receivedData {
    //  Decrpyt Data
    NSString *decrpytDataStr = [secuity aes256DecryptWithString:receivedData];
    [receivedDataArr addObject:decrpytDataStr];
    [_receivedTable reloadData];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSLog(@"~~~");
}

#pragma mark - UITableView
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.textLabel.text = [receivedDataArr objectAtIndex:indexPath.row];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [receivedDataArr count];
}

@end
