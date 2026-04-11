<?php
error_reporting(0);
if ($_POST){
	$id = $_POST['id'];
	$item = $_POST['item'];
	$num = $_POST['num'];
	$type = $_POST['type'];
	$id =='' && (die("角色ID错误")); 
	$item =='' && (die("物品ID错误")); 
	$num =='' && ($num="1"); 
	$url = "http://127.0.0.1:10003/Guozi";
    $data = get_post($url,"Id={$id}&type={$type}&item={$item}&num={$num}");
    die($data);
}

function get_post($url,$data){
	$curl = curl_init();
	curl_setopt($curl, CURLOPT_URL, $url);
	curl_setopt($curl, CURLOPT_POST, 1);
	curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, FALSE);
	curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, FALSE);
	curl_setopt($curl, CURLOPT_USERAGENT,"guozi"); 
	curl_setopt($curl, CURLOPT_HTTPHEADER, array('Content-Type:text/plain;charset=utf-8'));
	curl_setopt($curl, CURLOPT_POSTFIELDS,$data);
	curl_setopt($curl, CURLOPT_HEADER,0);
	curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
	$urls = curl_exec($curl);
	if (curl_errno($curl)) {return 'ERROR '.curl_error($curl);}
	curl_close($curl);
	return $urls ;
}
?>