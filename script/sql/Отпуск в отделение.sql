USE [test-report]
GO
/****** Object:  StoredProcedure [reporting].[Отпуск в отделение]    Script Date: 30.03.2014 20:15:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [reporting].[Отпуск в отделение]
(
	@d1	DATETIME                                                                   
	,@d2	DATETIME 
	,@rorgID int
	,@podr INT
	,@rsost_podrID int
	,@podr2 INT
	,@nom INT
	,@type_nom int
	,@ruserUID int
	,@SpisLec int
	,@rgr_nomID int
	,@rVidDejat int
)
as
begin
	DECLARE
		@status INT
		,@correct INT

	SET @status = [dbo]."Utils: GetIntSysParametr"('rStatusRealize')
	SET @correct = [dbo]."Utils: GetIntSysParametr"('rtype_prihodCorrect')

	select 
		T.date_doc
		,T.name_doc
		,t.nom
		,t.edizm,sum(t.numb) as numb
		,sum(t.summa) as summa
		,row_number() over (partition by T.name_doc order by date_doc, t.nom) as rnk
		,R.rpodrName
		,T.VidDeejat
		from
		(
			SELECT
				rperemdate_doc as DATE_DOC
				,'Перемещение ' + convert(varchar, ISNULL(rperemdate_doc,0),104) + '/' + ISNULL(rperemnum_doc,'')+' '+ISNULL(SHTAT.rShtatName,'') as NAME_DOC
				,nom.rnomName AS NOM
				,ei.red_izm_nomName  AS EDIZM
				,C.rpart_sost_peremnumb AS NUMB
				,B.rsost_peremser AS SER
				,C.rpart_sost_peremprihod AS PART
				,C.rpart_sost_peremnumb * C.rpart_sost_peremprice as SUMMA
				,convert(varchar,b.rsost_peremID) as typed
				,A.rperemotdel2
/*				,(SELECT rvid_dejat.rvid_dejatName
					from rperem 
						INNER JOIN rsost_perem ON rperem.rperemID = rsost_perem.rsost_peremperem 
						INNER JOIN rprihod ON rsost_perem.rsost_peremprihod = rprihod.rprihodID 
						INNER JOIN rvid_dejat ON rprihod.rprihodvid_dejat = rvid_dejat.rvid_dejatID
					where rperem.rperemID = A.rperemID 
						and	rsost_perem.rsost_peremID = B.rsost_peremID
						and (rvid_dejat.rvid_dejatID = @rVidDejat or isnull(@rVidDejat, -1) = -1) 
					) as VidDeejat
*/
, V.rvid_dejatName as VidDeejat

		FROM rperem A WITH(NOLOCK)
				INNER JOIN rsost_perem B WITH(NOLOCK) ON A.rperemID=B.rsost_peremperem
				INNER JOIN rpart_sost_perem C WITH(NOLOCK) ON C.rpart_sost_peremsost_perem=B.rsost_peremID
	INNER JOIN rprihod P ON B.rsost_peremprihod = P.rprihodID 
	INNER JOIN rvid_dejat V ON P.rprihodvid_dejat = V.rvid_dejatID
				LEFT JOIN dbo.uv_rpodr PODR WITH(NOLOCK) ON PODR.rpodrID = A.rperemotdel2
				LEFT JOIN dbo.uv_rShtat SHTAT WITH(NOLOCK) ON SHTAT.rShtatID = A.rperemmol2
				left join uv_rnom nom on nom.rnomID = b.rsost_peremnom
				--left join dbo.rspis_nom sp on sp.rspis_nomnom=nom.rnomID	and sp.rspis_nomspisok in (select top 1 sp.rspis_nomspisok from rspis_nom as sp where sp.rspis_nomnom=nom.rnomID and (sp.rspis_nomorg=@rorgID or @rorgID=-1) )
				left join uv_red_izm_nom ei  on ei.red_izm_nomID = b.rsost_peremed_izm_nom
			WHERE
				A.rperemotdel1=@podr
				AND A.rperemdate_doc<@d2 + 1
				AND A.rperemdate_doc>=@d1
				and (B.rsost_peremnom = @nom or isnull(@nom, -1)=-1)
				AND A.rperemstatus=@status
				AND (A.rperemotdel2=@podr2 or isnull(@podr2,-1)=-1)
				--AND (A.rperempost1 = @rsost_podrID or isnull(@rsost_podrID, -1) = -1)
				and (
				A.rperempost1 = @rsost_podrID
					or 
				(isnull(@rsost_podrID,-1) = -1 and A.rperempost1 in (select rsost_podrID from [reporting].[get_self_sost_podr](A.rperemotdel1, @ruserUID)) and @podr <> -1)
					or
				(isnull(@podr,-1) = -1 and isnull(@rsost_podrID,-1) = -1)
				)
				--and (sp.rspis_nomspisok=@SpisLec or isnull(@SpisLec,-1)=-1)
				and (exists (select 1 from rspis_nom aa where aa.rspis_nomnom = nom.rnomID and rspis_nomspisok = @SpisLec and (rspis_nomorg = @rorgID or rspis_nomorg is null)) or isnull(@SpisLec,-1) = -1)
				AND @type_nom = rnomtype_nom                                                                     
				AND A.rperemorg = @rorgID
				and (nom.rnomgroup = @rgr_nomID or isnull(@rgr_nomID,-1) = -1)
			and (V.rvid_dejatID = @rVidDejat or isnull(@rVidDejat, -1) = -1) 

		) t
		inner join rpodr R on r.rpodrID = T.rperemotdel2
		group by R.rpodrName, T.date_doc, T.name_doc, t.nom, t.edizm, T.VidDeejat
		order by T.date_doc, T.name_doc, t.nom, t.edizm, T.VidDeejat
end	

