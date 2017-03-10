

! ============================================== prediction Joint
    
    subroutine predictfam(np,b,nz,nva1,nva2,nst,typeof0,zi,HIHOut,&
    indID, tt1T, tt1dcT, icdctime, ntimeAll, nsujet, npred0, &
    window, nrec0, nrec, nrecT, vaxpred0,vaxdcpred0, icproba,nsample,&
    predAll, predIClow, predIChigh, frailfam0, frailind0, pred)
    
    implicit none
    
    integer::i,ii,iii,j,jj,k,typeof
    integer,intent(in)::np,nz,nva1,nva2,nst,typeof0,&
    icproba,nsujet,nsample, npred0, nrec0,indID,ntimeAll    
    double precision,intent(in):: frailfam0, frailind0
    double precision,dimension(np),intent(in)::b
    double precision,dimension(nz+6),intent(in)::zi
    double precision,dimension(np,np),intent(in)::HIHOut
    
    double precision,dimension(nsujet,nva1),intent(in)::vaxpred0
    double precision,dimension(npred0,nva2),intent(in)::vaxdcpred0
    double precision,dimension(npred0), intent(in):: tt1dcT
    double precision,dimension(nsujet), intent(in):: tt1T
    integer,dimension(npred0), intent(in):: icdctime, nrec, nrecT
    !integer,dimension(nsujet), intent(in):: icT
    
    double precision,dimension(ntimeAll)::window
    double precision,dimension(1,nsujet):: XbetapredRall, XbetapredRallalea
    double precision,dimension(npred0, nrec0):: XbetapredR, XbetapredRalea
    double precision,dimension(1,npred0)::XbetapredDC,XbetapredDCalea
    double precision::predTime2,alea,thetaalea,alphaalea,alpha,theta,eta,xi,etaalea,xialea !predTime,scR,shR,scDC,shDC,scRalea,shRalea,scDCalea,shDCalea            
    double precision::ss1,ss2
    double precision::predProb
    double precision::predAlllow,predAllhigh
    double precision,dimension(1,ntimeAll),intent(out)::predAll,predIClow,predIChigh,pred
    !double precision,intent(out)::predAll,predAlllow,predAllhigh, pred
    double precision,dimension(nz+2)::theR,theDC,theRalea,theDCalea
    double precision,dimension(2)::surv,lam, survDCi, survDCialea
    double precision,dimension(npred0)::survDC, hazDC, survDCalea, hazDCalea
    double precision,dimension(npred0)::survLTalea!,survU,survLT,survL,survUalea,survLalea
    double precision,dimension(npred0,nrec0)::survR,hazR,survRalea,hazRalea
    double precision,dimension(nrec0)::survRi,hazRi,survRialea!,hazRialea
    double precision,dimension(nsample,np)::balea
    double precision,dimension(nsample)::predProbaalea
    double precision,dimension(1,nva1)::coefBetaalea
    double precision,dimension(1,nva2)::coefBetadcalea
    !double precision,dimension(npred0)::trunctime,lowertime,uppertime,lowertime2,uppertime2
    double precision,dimension(1,nva1)::coefBeta
    double precision,dimension(1,nva2)::coefBetadc
    
     predAlllow = 0.d0
     predAllhigh = 0.d0 
	 
	typeof = typeof0
    
    coefBeta(1,:) = b((np-nva1-nva2+1):(np-nva2))
    coefBetadc(1,:) = b((np-nva2+1):np)
        
    XbetapredRall = matmul(coefBeta,transpose(vaxpred0))
    XbetapredDC = matmul(coefBetadc,transpose(vaxdcpred0))
    
    ! change XbetapredRall(1,nsujet) to XbetapredR(ng, nrec0)
    
    XbetapredR = 0.d0
    
    k=0
    do i=1, npred0
        ii=0
        do j=1,nsujet
            if(k.lt.j.and.j.le.k+nrec(i)) then
                ii=ii+1
                XbetapredR(i,ii)=XbetapredRall(1,j)
            end if
        end do 
    end do
 
    if (icproba.eq.1) then ! generation des parametres
        do j=1,nsample
            do i=1,np
                call rnormFam(b(i),sqrt(HIHOut(i,i)),alea)
                balea(j,i) = alea
            end do
        end do
    end if
                         
    !    write(*,*) 'predictfam: zi', zi    
    ! Calcul des risques de base
    ! A chaque fois, calculé pour : 
    ! DC au temps de base (predtimerec2(1,1)) et à l'horizon (predtimerec2(1,nrec0+2))
    ! Recurrence au temps de base et pour chaque temps de rechute entré (predtimerec2(i,ii))
    ! pour chaque prediction demandée
        
    do iii=1,ntimeAll
        predAlllow = 0.d0
        predAllhigh = 0.d0
        
        if (typeof.eq.0) then    
            theR = b(1:(nz+2))*b(1:(nz+2))
            theDC = b((nz+3):2*(nz+2))*b((nz+3):2*(nz+2))
            
            survR = 1.d0
            hazR = 0.d0
            survRi = 1.d0
            hazRi = 0.d0
            survDC = 1.d0
            hazDC = 0.d0
            survDCi = 1.d0
        
            k=0
            do i=1,npred0
                ii=0
                do j=1,nsujet
                    if((k.lt.j).and.(j.le.k+nrec(i))) then
                        ii=ii+1
                        predTime2 = tt1T(j)
                        call survival_frailty(predTime2,theR,theDC,nz+2,zi,surv,lam,nst)
                        survR(i,ii) = surv(1)
                            !hazR(i,ii) = lam(1) 
                    end if
                end do
                k=k+nrec(i)
            end do
            
            predTime2 = tt1dcT(indID)
            call survival_frailty(predTime2,theR,theDC,nz+2,zi,surv,lam,nst)
            survDCi(1) = surv(2)
            
            predTime2 = tt1dcT(indID)+window(iii)
            call survival_frailty(predTime2,theR,theDC,nz+2,zi,surv,lam,nst)
            survDCi(2) = surv(2)

            do i=1,npred0                
                predTime2 = tt1dcT(i)
                call survival_frailty(predTime2,theR,theDC,nz+2,zi,surv,lam,nst)
                survDC(i) = surv(2)
                !hazDC(i) = lam(2)
            end do             
        end if
            
            xi = b(np-nva1-nva2)
            alpha = b(np-nva1-nva2-1)
            eta = b(np-nva1-nva2-2)*b(np-nva1-nva2-2)
            theta = b(np-nva1-nva2-3)*b(np-nva1-nva2-3)        
        
!            pred1 = survDCi(1)**( ((frailind0**alpha)*frailfam0)*dexp(XbetapredDC(1,indID)) )
!            pred2 = survDCi(2)**( ((frailind0**alpha)*frailfam0)*dexp(XbetapredDC(1,indID)) )
!            write(*,*) 'tt1dcT(indID)', indID, tt1dcT(indID)
!            write(*,*) 'alpha, XbetapredDC(1)', alpha, XbetapredDC(1,indID)
!            write(*,*) 'survDCi', survDCi(1:2)
!            write(*,*) 'pred2,1', pred2, pred1        
!            write(*,*) '1-pred2/pred1', 1-pred2/pred1
            
            pred = 1-(survDCi(2)/survDCi(1))**((frailind0**alpha)*frailfam0*dexp(XbetapredDC(1,indID)))
            !write(*,*) 'surv2/1', survDCi(2)/survDCi(1)
            !write(*,*) 'power', ((frailind0**alpha)*frailfam0)*dexp(XbetapredDC(1,indID))
            !write(*,*) 'predictfam, pred', window, pred
            
            call gaulagJpredfam(ss1,ss2, indID, theta,alpha,eta,xi, &
            XbetapredR, XbetapredDC,survR,survDC,survDCi, icdctime, nrec0,nrecT, npred0)
                         
            predProb = ss1/ss2
            predAll(1,iii) = predProb
        
            !write(*,*) 'predictfam: ss1,ss2', ss1,ss2
            !write(*,*) 'predictfam: predprob', predProb
                
            !=============================================
            ! Variabilite des proba predites
            ! Creation d'un vecteur balea, qui correspond au vecteur b où chaque parametre
            ! est tiré au sort selon sa loi
!            seProba1(:)=0.d0; seProba2(:)=0.d0; seProba3(:)=0.d0;seProba4(:)=0.d0;
!            lowProba1(:)=0.d0; lowProba2(:)=0.d0; lowProba3(:)=0.d0;lowProba4(:)=0.d0;
!            highProba1(:)=0.d0; highProba2(:)=0.d0; highProba3(:)=0.d0;highProba4(:)=0.d0;
!            predProbaalea1(:,:)=0.d0;predProbaalea2(:,:)=0.d0;
!            predProbaalea3(:,:)=0.d0;predProbaalea4(:,:)=0.d0;
            
            if (icproba.eq.1) then ! calcul de l'intervalle de confiance seulement si demande
                predProbaalea = 0.d0
        
                do j=1,nsample
                    ss1 = 0.d0
                    ss2 = 0.d0
                    XbetapredRalea = 0.d0
                    XbetapredDCalea = 0.d0
                    survRalea = 1.d0
                    survRialea = 1.d0
                    hazRalea = 0.d0
                    survDCalea = 1.d0
                    hazDCalea = 0.d0
                    survDCialea = 1.d0
                    survLTalea = 1.d0
                    
                    coefBetaalea(1,:) = balea(j,(np-nva1-nva2+1):(np-nva2))
                    coefBetadcalea(1,:) = balea(j,(np-nva2+1):np)
        
                    XbetapredRallalea = matmul(coefBetaalea,transpose(vaxpred0))
                    XbetapredDCalea = matmul(coefBetadcalea,transpose(vaxdcpred0))
        
                    ! change XbetapredRallalea(1,nsujet) to XbetapredRalea(ng, nrec0)                
                
                    k=0
                    do i=1, npred0
                        ii=0
                        do jj=1,nsujet
                            if(k.lt.jj.and.jj.le.k+nrec(i)) then
                                ii=ii+1
                                XbetapredRalea(i,ii)=XbetapredRallalea(1,jj)
                            end if
                        end do 
                    end do
                                       
                    theRalea = balea(j,1:(nz+2))*balea(j,1:(nz+2))
                    theDCalea = balea(j,(nz+3):2*(nz+2))*balea(j,(nz+3):2*(nz+2))                
                           
                    k=0
                    do i=1,npred0
                        ii=0
                        do jj=1,nsujet
                            if((k.lt.jj).and.(jj.le.k+nrec(i))) then
                                ii=ii+1
                                predTime2 = tt1T(jj)
                                call survival_frailty(predTime2,theRalea,theDCalea,nz+2,zi,surv,lam,nst)
                                survRalea(i,ii) = surv(1)
                                !hazRalea(i,ii) = lam(1) 
                            end if
                        end do
                        k=k+nrec(i)
                    end do
                
                    predTime2 = tt1dcT(indID)
                    call survival_frailty(predTime2,theRalea,theDCalea,nz+2,zi,surv,lam,nst)
                    survDCialea(1) = surv(2)
                
                    predTime2 = tt1dcT(indID)+window(iii)
                    call survival_frailty(predTime2,theRalea,theDCalea,nz+2,zi,surv,lam,nst)
                    survDCialea(2) = surv(2)
                
                    do i=1,npred0                
                        predTime2 = tt1dcT(i)
                        call survival_frailty(predTime2,theRalea,theDCalea,nz+2,zi,surv,lam,nst)
                        survDCalea(i) = surv(2)
                        !hazDCalea(i) = lam(2)
                    end do
        
                    xialea = balea(j,np-nva1-nva2)
                    alphaalea = balea(j,np-nva1-nva2-1)
                    etaalea = balea(j,np-nva1-nva2-2)*balea(j,np-nva1-nva2-2)
                    thetaalea = balea(j,np-nva1-nva2-3)*balea(j,np-nva1-nva2-3)
                    
                    call gaulagJpredfam(ss1,ss2, indID, thetaalea,alphaalea,etaalea,xialea, &
                    XbetapredRalea, XbetapredDCalea,&
                    SurvRalea,survDCalea,survDCialea, icdctime, nrec0,nrecT, npred0)
                    
                    predProbaalea(j) = ss1/ss2
        !write(*,*) 'predictfam: predprobaalea(j)',j, predProbaalea(j)         
            end do
        !write(*,*) 'predictfam: predprobaalea, nsample', predProbaalea, nsample
        ! utilisation de la fonction percentile2 de aaUseFunction
            
            call percentile2(predProbaalea,nsample,predAlllow,predAllhigh)
! write(*,*) 'predict: predAlllow, high', predAlllow, predAllhigh 

            predIClow(1,iii) = predAlllow
            predIChigh(1,iii)= predAllhigh

        endif ! calcul de l'intervalle de confiance seulement si demande
    end do ! valeurs de window
    end subroutine predictfam

!=========================
! Uni: Prediction function for joint nested model, modified func1ped1 (numerator)
!=========================

    double precision function func1predfam(frail,frail2, indID, ptheta,palpha,peta,pxi,& 
    XbetapredR, XbetapredDC,survR,survDC,survDCi, icdctime, nrec0,nrecT, npred0)
    ! calcul de l integrant (numerateur de la fonction de prediction)
    
    use comon, only:typeof
    use donnees, only:w,x,w1,x1
     
    implicit none
    
    integer::nrec0,i,j,k, indID,npred0
    integer, dimension(npred0)::nrecT, icdctime
    double precision,intent(in)::frail, frail2
    double precision:: famHistALL, frailx, gu, gui, gw, termi,termi1,termi2,term
    !double precision:: XbetapredRi,XbetapredDCi
    double precision,dimension(npred0)::famHist
    double precision,dimension(npred0, nrec0)::XbetapredR
    double precision,dimension(1,npred0)::XbetapredDC
    double precision,dimension(npred0)::survDC
    double precision,dimension(2)::survDCi 
    !double precision,dimension(nrec0)::survRi
    double precision,dimension(npred0,nrec0)::survR
    double precision,dimension(npred0)::survDCfam, survRfam
    double precision::ptheta,palpha,peta, pxi, gammaJ

! npred0 = family size
! nreci = number of recurrents before time t
! survDC(i, 1) = surv(t); survDC(i,2)= surv(t+w)
! 
    
    survRfam = 1.d0
    famHistALL = 1.d0
    term = 0.d0
    termi = 0.d0
    termi1 = 0.d0
    termi2 = 0.d0
    gu = 0.d0
    gw = 0.d0
    famHist =1.d0

    
    do j=1,nrec0
        survRfam(indID) = survRfam(indID)*survR(indID,j)**(&
        (frail*frail2**pxi)*dexp(XbetapredR(indID,j)))
    end do

    termi =    (frail*(frail2**pxi))**nrecT(indID)
    termi1 = survDCi(1)**(((frail**palpha)*frail2)*dexp(XbetapredDC(1,indID)) )
    termi2 = survDCi(2)**(((frail**palpha)*frail2)*dexp(XbetapredDC(1,indID)) )
    term = termi*(termi1-termi2)*survRfam(indID)
    
    do i=1, npred0 
        if(i.ne.indID) then
        do k=1,32
            frailx = x1(k)
            gu = (frailx**(1.d0/ptheta -1.d0) * exp(-frailx/ptheta)) / &
                    (ptheta**(1.d0/ptheta) * gammaJ(1.d0/ptheta))  
            do j=1, nrec0
                survRfam(i)=survRfam(i)*survR(i,j)**(frailx*(frail2**pxi)*dexp(XbetapredR(i,j)))
            end do
            survDCfam(i)=((frailx**palpha)*frail2)**icdctime(i)*&
                    survDC(i)**( (frailx**palpha)*frail2*dexp(XbetapredDC(1,i)) )
            famHist(i) = famHist(i) + &
                    w1(k)*(frailx*(frail2**pxi))**nrecT(i)*survRfam(i)*survDCfam(i)*gu            
        end do
        end if
    end do 

    do i=1,npred0
         famHistALL = famHistALL*famHist(i)
    end do    
    
    gui = (frail**(1.d0/ptheta -1.d0)*exp(-frail/ptheta))/(ptheta**(1.d0/ptheta)*gammaJ(1.d0/ptheta))  
    gw = (frail2**(1.d0/peta -1.d0)*exp(-frail2/peta))/(peta**(1.d0/peta)*gammaJ(1.d0/peta))  

    func1predfam = term*famHistALL*gui*gw    
    
    return
    
    end function func1predfam


!=========================
! Uni: Prediction function for joint nested model, modified func2ped1 (denominator)
!=========================

    double precision function func2predfam(frail,frail2, indID, ptheta,palpha,peta,pxi,& 
    XbetapredR, XbetapredDC,survR,survDC,survDCi, icdctime, nrec0,nrecT, npred0)
    ! calcul de l integrant (denominateur de la fonction de prediction)
    
    use comon, only:typeof
    use donnees, only:w,x,w1,x1
     
    implicit none
    
    integer::nrec0,i,j,k, indID,npred0
    integer, dimension(npred0)::nrecT, icdctime
    double precision,intent(in)::frail, frail2
    double precision:: famHistALL, frailx, gu, gui, gw, termi,termi1,term
    !double precision:: XbetapredRi,XbetapredDCi
    double precision,dimension(npred0)::famHist
    double precision,dimension(npred0, nrec0)::XbetapredR
    double precision,dimension(1,npred0)::XbetapredDC
    double precision,dimension(npred0)::survDC
    double precision,dimension(2)::survDCi 
    !double precision,dimension(nrec0)::survRi
    double precision,dimension(npred0,nrec0)::survR
    double precision,dimension(npred0)::survDCfam, survRfam
    double precision::ptheta,palpha,peta, pxi, gammaJ

! npred0 = family size
! nreci = number of recurrents before time t
! survDC(i, 1) = surv(t); survDC(i,2)= surv(t+w) 
    
    survRfam = 1.d0
    famHist = 1.d0
    famHistALL = 1.d0
    term = 0.d0
    termi = 0.d0
    termi1 = 0.d0
    gu = 0.d0
    gw = 0.d0
    
    do j=1,nrec0
        survRfam(indID) = survRfam(indID)*survR(indID,j)**(&
        (frail*frail2**pxi)*dexp(XbetapredR(indID,j)))
    end do

    termi =    (frail*(frail2**pxi))**nrecT(indID)
    termi1 = survDCi(1)**(((frail**palpha)*frail2)*dexp(XbetapredDC(1,indID)))
!    termi2 = survDCi(2)**((frail**palpha)*frail2)*dexp(XbetapredDC(indID))
    term = termi*termi1*survRfam(indID)
    
    do i=1, npred0 
        if(i.ne.indID) then
        do k=1,32
            frailx = x1(k)
            gu = (frailx**(1.d0/ptheta -1.d0) * exp(-frailx/ptheta)) / &
                    (ptheta**(1.d0/ptheta) * gammaJ(1.d0/ptheta))              
            do j=1, nrec0
                survRfam(i)=survRfam(i)*survR(i,j)**(frailx*(frail2**pxi)*dexp(XbetapredR(i,j)))
            end do
            survDCfam(i)=((frailx**palpha)*frail2)**icdctime(i)*&
                    survDC(i)**( (frailx**palpha)*frail2*dexp(XbetapredDC(1,i)) )
            famHist(i) = famHist(i) + &
                    w1(k)*(frailx*frail2**pxi)**nrecT(i)*survRfam(i)*survDCfam(i)*gu
                !famHist1(i) = famHist1(i) + w(k)*famHist(i)
        end do
        end if
    end do 

    do i=1,npred0
        famHistALL = famHistALL*famHist(i)
    end do
    
    gui = (frail**(1.d0/ptheta -1.d0)*exp(-frail/ptheta))/(ptheta**(1.d0/ptheta)*gammaJ(1.d0/ptheta))  
    gw = (frail2**(1.d0/peta -1.d0)*exp(-frail2/peta))/(peta**(1.d0/peta)*gammaJ(1.d0/peta))  
    func2predfam = term*famHistALL*gui*gw
    
    return
    
    end function func2predfam
 
    
!=========================
! Calcul des intégrales
!=========================
    subroutine gaulagJpredfam(ss1,ss2, indID, ptheta,palpha,peta,pxi, &
        XbetapredR, XbetapredDC,survR,survDC,survDCi, icdctime, nrec0,nrecT, npred0)
 
    
!        double precision function func2predfam(frail,frail2, indID, ptheta,palpha,peta,pxi, 
!        XbetapredR, XbetapredDC,SurvR,survDC,survDCi, icdctime, nrec0,nrecT, npred0)
    
!    use tailles
    use comon,only:typeof
    use donnees,only:w,x,w1,x1
    
    implicit none

    integer,intent(in)::nrec0, indID, npred0
    double precision,intent(out)::ss1,ss2
    double precision::ssu1,ssu2!,XbetapredRi,XbetapredDCi
    double precision::auxfunca11,auxfunca12,var1,var2
    double precision,external :: func1predfam,func2predfam
    integer, dimension(npred0):: icdctime, nrecT
    double precision,dimension(npred0, nrec0)::XbetapredR
    double precision,dimension(1,npred0)::XbetapredDC
    double precision,dimension(npred0)::survDC!, famHist
    double precision,dimension(2)::survDCi 
    !double precision,dimension(nrec0)::survRi
    double precision,dimension(npred0,nrec0)::survR
    
    !double precision::survLT !!
    double precision::ptheta,palpha, peta, pxi
    integer:: j,jj

! gauss laguerre
! func1 est l integrant, ss le resultat de l integrale sur 0 ,  +infty

    ss1=0.d0
    ss2=0.d0
    ssu1=0.d0
    ssu2=0.d0
  
    
    if (typeof == 1)then
        do j=1,20
            var2 = x(j)
            do jj=1,20
                var1 = x(jj)
                auxfunca11 = func1predfam(var1,var2, indID, ptheta,palpha,peta,pxi,&
                    XbetapredR, XbetapredDC,survR,survDC,survDCi, icdctime, nrec0,nrecT, npred0)                
                auxfunca12 = func2predfam(var1,var2, indID, ptheta,palpha,peta,pxi,&
                    XbetapredR, XbetapredDC,survR,survDC,survDCi, icdctime, nrec0,nrecT, npred0)                    
                ssu1 = ssu1 + w(jj)*(auxfunca11)
                ssu2 = ssu2 + w(jj)*(auxfunca12)
                !write(*,*) 'x(jj), w(jj),', x(jj), w(jj)
                !write(*,*) 'gaulagJpredfam: ssu1,ssu2', jj,ssu1, ssu2
                !write(*,*) 'gaulagJpredfam: auxfunca11,12', auxfunca11, auxfunca12
            end do
                ss1 = ss1 + w(j)*ssu1
                ss2 = ss2 + w(j)*ssu2 
                !write(*,*) 'x(j), w(j),', j, x(j), w(j)
                !write(*,*) 'gaulagJpredfam: ss1,ss2', j, ss1, ss2
        end do
    else
        do j=1,32
            var2 = x1(j)
            do jj=1,32
                var1 = x1(jj)
                auxfunca11 = func1predfam(var1,var2, indID, ptheta,palpha,peta,pxi,& 
                    XbetapredR, XbetapredDC,survR,survDC,survDCi, icdctime, nrec0,nrecT, npred0)
                auxfunca12 = func2predfam(var1,var2, indID, ptheta,palpha,peta,pxi,& 
                    XbetapredR, XbetapredDC,survR,survDC,survDCi, icdctime, nrec0,nrecT, npred0)            
                ssu1 = ssu1 + w1(jj)*(auxfunca11)
                ssu2 = ssu2 + w1(jj)*(auxfunca12)
            end do
                ss1 = ss1 + w1(j)*ssu1
                ss2 = ss2 + w1(j)*ssu2 
        end do
    end if
    
    end subroutine gaulagJpredfam   


! Pour tirer au sort aléatoirement dans une loi normale de moyenne m et d'écart-type s
    subroutine rnormFam(m,s,res)
    
    double precision,intent(in)::m,s
    double precision,intent(out)::res
    double precision::alea1,alea2,UNIRAN
    double precision,parameter::pi=3.1415926536
    
    alea1 = UNIRAN()
    alea2 = UNIRAN()
    
    res = m + (s * sqrt(-2.d0*log(alea1)) * cos(2.d0*pi* alea2))
    
    end subroutine rnormFam