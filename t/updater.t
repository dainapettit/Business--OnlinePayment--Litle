#!/usr/bin/perl -w

use Test::More qw(no_plan);
use Data::Dumper; 
## grab info from the ENV
my $login = $ENV{'BOP_USERNAME'} ? $ENV{'BOP_USERNAME'} : 'TESTMERCHANT';
my $password = $ENV{'BOP_PASSWORD'} ? $ENV{'BOP_PASSWORD'} : 'TESTPASS';
my $merchantid = $ENV{'BOP_MERCHANTID'} ? $ENV{'BOP_MERCHANTID'} : 'TESTMERCHANTID';
my @opts = ('default_Origin' => 'RECURRING');

my $str = do { local $/ = undef; <DATA> };
my $data;
eval($str);

my $authed = 
    $ENV{BOP_USERNAME}
    && $ENV{BOP_PASSWORD}
    && $ENV{BOP_MERCHANTID};

use_ok 'Business::OnlinePayment';

SKIP: {
    skip "No Auth Supplied", 3, !$authed;
    ok( $login, 'Supplied a Login' );
    ok( $password, 'Supplied a Password' );
    like( $merchantid, qr/^\d+/, 'MerchantID');
}

my %orig_content = (
    login          => $login,
    password       => $password,
    merchantid     => $merchantid,
    action         => 'Account Update',
);

my $batch_id = time;
SKIP: {
    skip "No Test Account setup",54 if ! $authed;
### Litle Updater Tests
    print '-'x70;
    print "Updater TESTS\n";
    my $tx = Business::OnlinePayment->new("Litle", @opts);
    foreach my $account ( @{$data->{'updater_request'}} ){
        my %content = %orig_content;
        $content{'type'} = $account->{'card'};
        $content{'card_number'} = $account->{'account'};
        $content{'expiration'} = $account->{'expdate'};
        $content{'customer_id'} = $account->{'id'};
        $content{'invoice_number'} = $account->{'id'};
        ## get the response validation set for this order
        
        $tx->add_item(\%content);

    }
    $tx->test_transaction(1);
    $tx->create_batch( 
        method     => 'https',
        login      => $login,
        password   => $password,
        merchantid => $merchantid,
        batch_id   => $batch_id,
    );
}

#        my ($resp_validation) = grep { $_->{'id'} ==  $account->{'id'} } @{ $data->{'updater_response'} };
#        {
#            tx_check(
#                $tx,
#                desc          => "Auth Only",
#                is_success    => $resp_validation->{'Message'} eq 'Approved' ? 1 : 0,
#                result_code   => $resp_validation->{'Response Code'},
#                error_message => $resp_validation->{'Message'},
#                authorization => $resp_validation->{'Auth Code'},
#                avs_code      => $resp_validation->{'AVS Result'},
#                cvv2_response => $resp_validation->{'Card Validation Result'},
#            );
#
#            $auth_resp{ $account->{'OrderId'} } = $tx->order_number if $tx->is_success;
#        }

#-----------------------------------------------------------------------------------
#
sub tx_check {
    my $tx = shift;
    my %o  = @_;

    $tx->test_transaction(1);
    $tx->submit;

    is( $tx->is_success,    $o{is_success},    "$o{desc}: " . tx_info($tx) );
    is( $tx->result_code,   $o{result_code},   "result_code(): RESULT" );
    is( $tx->error_message, $o{error_message}, "error_message() / RESPMSG" );
    if( $o{authorization} ){
        is( $tx->authorization, $o{authorization}, "authorization() / AUTHCODE" );
    }
    if( $o{avs_code} ){
        is( $tx->avs_code,  $o{avs_code},  "avs_code() / AVSADDR and AVSZIP" );
    }
    if( $o{cvv2_response} ){
        is( $tx->cvv2_response, $o{cvv2_response}, "cvv2_response() / CVV2MATCH" );
    }
    like( $tx->order_number, qr/^\w{5,19}/, "order_number() / PNREF" );
}

sub tx_info {
    my $tx = shift;

    no warnings 'uninitialized';

    return (
        join( "",
            "is_success(",     $tx->is_success,    ")",
            " order_number(",  $tx->order_number,  ")",
            " error_message(", $tx->error_message, ")",
            " result_code(",   $tx->result_code,   ")",
            " auth_info(",     $tx->authorization, ")",
            " avs_code(",      $tx->avs_code,      ")",
            " cvv2_response(", $tx->cvv2_response, ")",
        )
    );
}

sub expiration_date {
    my($month, $year) = (localtime)[4,5];
    $year++;       # So we expire next year.
    $year %= 100;  # y2k?  What's that?

    return sprintf("%02d%02d", $month, $year);
}

__DATA__
$data= {
'updater_request' => [
  { id  =>  1,
    account => '4457010000000009',
    expdate => '0912',
    card  =>  'VI',
  },
  { id  =>  2,
    account => '4457003100000003',
    expdate => '0505',
    card  =>  'VI',
  },
  { id  =>  3,
    account => '4457000300000007',
    expdate => '0107',
    card  =>  'VI',
  },
  { id  =>  4,
    account => '4457000400000006',
    expdate => '0000',
    card  =>  'VI',
  },
  { id  =>  5,
    account => '4457000400000006',
    expdate => '0210',
    card  =>  'VI',
  },
  { id  =>  6,
    account => '5112010000000003',
    expdate => '0205',
    card  =>  'MC',
  },
  { id  =>  7,
    account => '5112002200000008',
    expdate => '0912',
    card  =>  'MC',
  },
  { id  =>  8,
    account => '5112000200000002',
    expdate => '0508',
    card  =>  'MC',
  },
  { id  =>  9,
    account => '5112002100000009',
    expdate => '0000',
    card  =>  'MC',
  },
  { id  =>  10,
    account => '5112000400400018',
    expdate => '0210',
    card  =>  'MC',
  },
],

'updater_response' => [
 { id =>  1,
   type => 'VI',
   code =>  '000',
   message => 'Approved',
 },
 { id =>  2,
   type => 'VI',
   code =>  '000',
   message => 'Approved',
 },
 { id =>  3,
   type => 'VI',
   code =>  '000',
   message => 'Approved',
 },
 { id =>  4,
   type => 'VI',
   code =>  '320',
   message => 'Invalid Expiration Date',
 },
 { id =>  5,
   type => 'VI',
   code =>  '301',
   message => 'Invalid Account Number',
 },
 { id =>  6,
   type => 'MC',
   code =>  '000',
   message => 'Approved',
 },
 { id =>  7,
   type => 'MC',
   code =>  '000',
   message => 'Approved',
 },
 { id =>  8,
   type => 'MC',
   code =>  '000',
   message => 'Approved',
 },
 { id =>  9,
   type => 'VI',
   code =>  '320',
   message => 'Invalid Expiration Date',
 },
 { id =>  10,
   type => 'VI',
   code =>  '301',
   message => 'Invalid Account Number',
 },
 ],

        };