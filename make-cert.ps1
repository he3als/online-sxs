$TextExtension =  @(
# Enhanced Key Usage
'2.5.29.37={text}1.3.6.1.4.1.311.10.3.6,1.3.6.1.5.5.7.3.3',
# Basic Constraints
'2.5.29.19={text}false',
# Subject Alternative Name
'2.5.29.17={text}DirectoryName=SERIALNUMBER="229879+500176",OU=Microsoft Ireland Operations Limited'
)

$params = @{
	Type = 'Custom'
	Subject = 'CN=Microsoft Windows, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
	TextExtension = $TextExtension
	KeyUsage = 'None'
	KeyAlgorithm = 'RSA'
	KeyLength = 2048
	NotAfter = (Get-Date).AddMonths(999)
	CertStoreLocation = 'Cert:\LocalMachine\My'
}
New-SelfSignedCertificate @params

<# 

2.5.29.37=Windows System Component Verification (1.3.6.1.4.1.311.10.3.6), Code Signing (1.3.6.1.5.5.7.3.3)
2.5.29.14=a9fa06119e808280f431cb3cee471aeffc4951b7
2.5.29.17=Directory Address:SERIALNUMBER="229879+500176", OU=Microsoft Ireland Operations Limited
2.5.29.35=KeyID=a92902398e16c49778cd90f99e4f9ae17c55af53
2.5.29.31=[1]CRL Distribution Point: Distribution Point Name:Full Name:URL=http://www.microsoft.com/pkiops/crl/MicWinProPCA2011_2011-10-19.crl
1.3.6.1.5.5.7.1.1=[1]Authority Info Access: Access Method=Certification Authority Issuer (1.3.6.1.5.5.7.48.2), Alternative Name=URL=http://www.microsoft.com/pkiops/certs/MicWinProPCA2011_2011-10-19.crt
2.5.29.19=Subject Type=End Entity, Path Length Constraint=None

#>

# Issuer = 'CN=Microsoft Windows Production PCA 2011, O=Microsoft Corporation, L=Redmond, S=Washington, C=US'
