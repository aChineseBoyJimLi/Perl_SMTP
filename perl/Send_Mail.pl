use strict;
use lib "../lib";
use Net::SMTP_auth;
use Encode;
use JSON;

sub SendMail{
    # 读取配置文件
    my $json = "";
    open(JSON, '../conf/conf.json') or die "can't open file";

    while(<JSON>){
        $json = $json . $_;
    }
    close JSON;

    my $decoded_json = decode_json( $json );

    my $user_name = $decoded_json->{user_name};         # 用户名
    my $mail_address = $decoded_json->{mail_address};   # 邮箱地址
    my $mail_server = $decoded_json->{mail_server};     # 邮箱服务器
    my $mail_password = $decoded_json->{mail_password}; # 邮箱密码

    # 输入发送目标
    print "请输入收件人邮箱(群发请用“;”号隔开): ";
    
    my $send_to = <STDIN>;  # 收件人列表
    chomp $send_to;
    my @targets = split(";",$send_to);
    if($send_to eq ""){
        print "不能为空，取消发送";
        return;
    }

    # 输入标题
    print "请输入邮件标题：";
    my $subject = <STDIN>;
    chomp $subject;
    if($subject eq ""){
        print "不能为空，取消发送";
        return;
    }

    # 输入内容文件
    print "选择/mails目录下的一个文件作为内容发送: ";
    my $mail_path = <STDIN>;
    chomp $mail_path;
    if($mail_path eq ""){
        print "不能为空，取消发送";
        return;
    }
    my $content = "";   # 邮件内容
    open(CONTENT, '../mails/'. $mail_path) or die "can't open file";

    while(<CONTENT>){
        $content = $content . $_;
    }
    print $content;
    close CONTENT;

    # 确认发送
    print "是否确认发送(yes): ";
    my $submit = <STDIN>;
    chomp $submit;
    if($submit eq "yes"){
        print "发送中.......\n";

        # 发送邮件
        my $smtp = Net::SMTP_auth->new($mail_server, Timeout=>520, Debug=>1) or die "Error.\n";
        $smtp->auth('LOGIN', $user_name, $mail_password);

        foreach my $mailto(@targets){
            $smtp->mail($mail_address);
            $smtp->to($mailto);
            $smtp->data();
            $smtp->datasend("To: $mailto\n");
            $smtp->datasend("From: $mail_address\n");
            $smtp->datasend("Subject: $subject\n");
            $smtp->datasend("\n");
            $smtp->datasend("$content\n\n");
            $smtp->dataend();
        }

        $smtp->quit;

        print "已发送\n";
        return;
    }
    else{
        print "取消发送";
        return;
    }

}

SendMail();