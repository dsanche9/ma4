
<?php
//result.php
$_SESSION['email']=$_POST['email'];
$_SESSION['phone']=$_POST['phone'];

//$uploaddir = 'www/var/html/';
$uploadfile = basename($_FILES['userfile']['name']);
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

//create a bucke
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
<img src="<?php echo $url; ?>" alt="Picture">




