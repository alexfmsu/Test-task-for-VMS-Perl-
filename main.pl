use 5.22.0;
use strict;
use warnings;

use constant MAX_FILE_SIZE => 1024*1024; # optional

sub open_file{
    my $filename = shift;
    
    open(my $fh, '>', $filename) or die "Cannot open $filename: $!";
    
    return $fh;
}

sub close_file{
    my $fh = shift;
    
    close($fh) || warn "Cannot close filehandle: $!";
}

my $from_pattern = qr{
    ^
    From
    \s
    (?<mail>\b[\w\.-]+@[\w\.-]+\.\w{2,4}\b)     # or qr/\S+/ if no need to check email matching
    \s+
    (?<date>.+)
}xo;

my $infile = 'unix.mailbox';
my $outfile;

my $fh_in;
my $fh_out;

my %senders = ();
my $cur_sender;

my $mail;
my $date;

open($fh_in, '<', $infile) or die "Cannot open $infile: $!";
binmode($fh_in, ":crlf");

while(<$fh_in>){
    if(/$from_pattern/){
        $mail = $+{mail};
        $date = $+{date};
        
        $outfile = $mail.'/'.$date;
        
        if(not exists $senders{$outfile}){
            unless(-e $mail){
                mkdir $mail or die $!;
            }
            
            $cur_sender = $senders{$outfile} = {};
            
            $cur_sender->{file_num} = 0;
            $cur_sender->{filesize} = 0;
            $cur_sender->{fh} = open_file($outfile . '_' . $cur_sender->{file_num});
        }else{
            $cur_sender = $senders{$outfile};
            
            if($cur_sender->{is_full}){
                close_file($cur_sender->{fh});
                
                $cur_sender->{file_num}++;
                $cur_sender->{filesize} = 0;
                $cur_sender->{is_full} = 0;
                $cur_sender->{fh} = open_file($outfile . '_' . $cur_sender->{file_num});
            }    
        }
        
        $fh_out = $cur_sender->{fh};
    }
    
    last unless defined $fh_out;
    
    print $fh_out $_;
    
    unless($cur_sender->{is_full}){
        $cur_sender->{filesize} += length $_;
        
        if($cur_sender->{filesize} > MAX_FILE_SIZE){
            $cur_sender->{is_full} = 1;
        }
    }
}

close($fh_in);
close($_->{fh}) for values %senders;
