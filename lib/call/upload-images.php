<?php
include '../include/db_con.php';
include '../func/helper.php';

$helper = new Helper;
$response = new stdClass;
$response->status = null;
$response->error = '';

if (isset($_POST['profile_setup'])) {

    $files = $_FILES['files']['name'];
    $tmpFile = $_FILES['files']['tmp_name'];
    $images = array();

    $imapeUrl = '';
    $uploaded = false;

    foreach ($files as $key => $value) {
        foreach ($tmpFile as $key2 => $tmpFileValue) {
            $imgUid = uniqid();
            $fileDestionation = "../uploads/" . $imgUid . $value;
            $fileDestionation2 = "uploads/" . $imgUid . $value;
            $path = "https://aboostoplus.com/" . $fileDestionation2;
            if (move_uploaded_file($tmpFileValue, $fileDestionation)) {
                $uploaded = true;
                $imapeUrl = $path;
                array_push($images, $path);
            }
        }
    }
    if (isset($_POST['signup_data'])) {
        $signupData = $_POST['signup_data'];
        $email = $signupData['email'];
        $firsName = $signupData['first_name'];
        $lastName = $signupData['last_name'];
        $password = $signupData['password'];
        $phone = $signupData['phone'];
        $address = $signupData['address'];
        $state = $signupData['state'];
        $city = $signupData['city'];
        $leadUid = $signupData['lead_uid'];
        $profileImage = $imapeUrl;
        $userType = $signupData['user_type'];
        $uniqueId = $signupData['unique_id'];
        $notificationId = $signupData['notification_id'];
        $exec = $helper->createUserAccount($uniqueId, $firsName, $lastName, $email, $password, $phone, $city, $userType, $leadUid, $address, $notificationId, $profileImage, $state);

        if ($uploaded == true && $exec == true) {
            $response->status = true;
            $response->imagePath = $images;
            // $response->mFileNames = $mFileNames;
            $response->message = 'Successful';
        } else {
            $response->status = false;

            $response->message = 'Unable To Upload Image, Please try again';
        }
    }
} else if (isset($_POST['upload_images'])) {

    $files = $_FILES['files']['name'];
    $tmpFile = $_FILES['files']['tmp_name'];
    $images = array();

    $imapeUrl = '';
    $uploaded = false;

    foreach ($files as $key => $value) {
        foreach ($tmpFile as $key2 => $tmpFileValue) {
            $imgUid = uniqid();
            $fileDestionation = "../uploads/" . $imgUid . $value;
            $fileDestionation2 = "uploads/" . $imgUid . $value;
            $path = "https://aboostoplus.com/" . $fileDestionation2;
            if (move_uploaded_file($tmpFileValue, $fileDestionation)) {
                $uploaded = true;
                $imapeUrl = $path;
                array_push($images, $path);
            }
        }
    }



    if ($uploaded == true) {
        $response->status = true;
        $response->imagePath = $images;
        // $response->mFileNames = $mFileNames;
        $response->message = 'Successful';
    } else {
        $response->status = false;

        $response->message = 'Unable To Upload Image, Please try again';
    }
}

header('Content-type: application/json');
echo json_encode($response);
