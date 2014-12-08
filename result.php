<!DOCTYPE html>
<html>
<title>ma4</title>
<body>
<?php
//result.php
$_SESSION['email']=$_POST['email'];
$_SESSION['phone']=$_POST['phone'];

$uploaddir = ''; //maybe leave it on www.
$uploadfile = $uploaddir.basename($_FILES['userfile']['name']);
echo '<pre>';
if(move_uploaded_file($_FILES['userfile']['tmp_name'], $uploadfile)){
	echo "File successfully uploaded. \n";
} else {
	echo "error";
}

echo 'Here is some more debugging info:';
print_r($_FILES);
print "</pre>";


require 'vendor/autoload.php';
use Aws\S3\S3Client;

//creates a client with my key and secret?
$client = S3Client::factory();

//create a bucket
$bucket = uniqid("backend1", true);
echo "Creating bucket named {$bucket}\n";
$result = $client->createBucket(array(
'Bucket' => $bucket
));

$client->waitUntilBucketExists(array('Bucket'=> $bucket));

$key = $uploadfile;
echo "Creating a new object with key {$key}\n";
$result = $client->putObject(array(
'ACL' => 'public-read',	
'Bucket' => $bucket,
'Key' => $key,
'SourceFile' => $uploadfile
));

$url= $result['ObjectURL'];
echo $_SESSION['email'] .PHP_EOL;
echo $_SESSION['phone'] .PHP_EOL; 

//hace lo de img blabla con un simple echo $url y luego 

?>
<br>
<img src="<?php echo $url; ?>" alt="Picture">
</body>
</html>



